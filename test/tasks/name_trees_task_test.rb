require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'

class NameTreesTaskTest < Minitest::Test

  class << self
    def setup_tree_class
      Tree.class_eval do
        class << self
          attr_accessor :instances
          def find_each
            (instances || []).each { |t| yield t }
          end
        end
      end
    end

    attr_accessor :response_data
  end

  def setup
    self.class.setup_tree_class

    @tree = Tree.new
    @tree.define_singleton_method(:attributes) do
      @attrs ||= { 'name' => nil, 'treedb_com_id' => '1' }
    end
    @tree.define_singleton_method(:update!) do |attrs|
      attributes.merge!(attrs.transform_keys(&:to_s))
    end
    Tree.instances = [@tree]
    self.class.response_data = [
      { 'message' => { 'content' => 'Fancy Tree' } },
      { 'message' => { 'content' => 'YES' } }
    ]

    Kernel.module_eval do
      alias_method :orig_require, :require
      def require(name)
        return true if name == 'ollama-ai'
        orig_require(name)
      end
    end
    @require_patched = true

    @previous_ollama = Object.const_get(:Ollama) if Object.const_defined?(:Ollama)
    Object.send(:remove_const, :Ollama) if Object.const_defined?(:Ollama)

      stub_ollama = Class.new do
        class << self
          attr_accessor :call_count, :last_params, :params_list
        end

        attr_reader :last_chat_params

        def initialize(credentials:); end

        def chat(payload, **_opts)
          self.class.call_count = (self.class.call_count || 0) + 1
          self.class.last_params = payload
          self.class.params_list ||= []
          self.class.params_list << payload
          @last_chat_params = payload
          data = NameTreesTaskTest.response_data
          if data.is_a?(Array)
            NameTreesTaskTest.response_data = data[1..] || []
            data = data.first
          end
          data || { 'message' => { 'content' => 'Fancy Tree' } }
        end
      end
      Object.const_set(:Ollama, stub_ollama)
      Ollama.call_count = 0

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/name_trees.rake', __dir__)
  end

  def teardown
    Object.send(:remove_const, :Ollama)
    Object.const_set(:Ollama, @previous_ollama) if @previous_ollama
    if @require_patched
      Kernel.module_eval do
        alias_method :require, :orig_require
        remove_method :orig_require
      end
    end
    Tree.instances = nil
  end

  def test_rake_task_updates_tree_name
    Rake.application['db:name_trees'].invoke
    assert_equal 'Fancy Tree', @tree.attributes['name']
    assert_equal 'Qwen3:0.6b', @tree.attributes['llm_model']
  end

  def test_response_is_cleaned_of_think_tags
    self.class.response_data = [
      { 'message' => { 'content' => '<think>thinking</think>' } },
      { 'message' => { 'content' => "\n\nCrimson Cap" } },
      { 'message' => { 'content' => 'YES' } }
    ]
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_equal 'Crimson Cap', @tree.attributes['name']
  end

  def test_skips_trees_with_existing_name
    @tree.attributes['name'] = 'Existing'
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_equal 'Existing', @tree.attributes['name']
    assert_equal 0, Ollama.call_count
  end

  def test_retries_when_name_too_short
    self.class.response_data = [
      { 'message' => { 'content' => 'A' } },
      { 'message' => { 'content' => 'Valid' } },
      { 'message' => { 'content' => 'YES' } }
    ]
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_equal 'Valid', @tree.attributes['name']
    assert_equal 3, Ollama.call_count
  end

  def test_retries_when_name_too_long
    long_name = 'A' * 151
    self.class.response_data = [
      { 'message' => { 'content' => long_name } },
      { 'message' => { 'content' => 'Valid Name' } },
      { 'message' => { 'content' => 'YES' } }
    ]
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_equal 'Valid Name', @tree.attributes['name']
    assert_equal 3, Ollama.call_count
  end

  def test_retries_until_valid_name_received
    self.class.response_data = [
      { 'message' => { 'content' => 'A' } },
      { 'message' => { 'content' => 'B' } },
      { 'message' => { 'content' => 'Valid Name' } },
      { 'message' => { 'content' => 'YES' } }
    ]
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_equal 'Valid Name', @tree.attributes['name']
    assert_equal 4, Ollama.call_count
  end

  def test_retries_more_than_three_times_until_success
    long_name = 'A' * 151
    self.class.response_data = [
      { 'message' => { 'content' => long_name } },
      { 'message' => { 'content' => 'BadName' } },
      { 'message' => { 'content' => 'NO' } },
      { 'message' => { 'content' => 'Another Bad Name' } },
      { 'message' => { 'content' => 'NO' } },
      { 'message' => { 'content' => 'Valid Name' } },
      { 'message' => { 'content' => 'YES' } }
    ]
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_equal 'Valid Name', @tree.attributes['name']
    assert_equal 7, Ollama.call_count
  end

  def test_retries_when_verification_fails
    self.class.response_data = [
      { 'message' => { 'content' => 'Bad Name 123' } },
      { 'message' => { 'content' => 'NO' } },
      { 'message' => { 'content' => 'Oak' } },
      { 'message' => { 'content' => 'YES' } }
    ]
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_equal 'Oak', @tree.attributes['name']
    assert_equal 4, Ollama.call_count
  end

  def test_neighbor_names_included_in_prompt
    @tree.define_singleton_method(:treedb_lat) { 0.0 }
    @tree.define_singleton_method(:treedb_long) { 0.0 }
    neighbor = Struct.new(:name).new('Oak')
    @tree.define_singleton_method(:neighbors_within) { |_radius| [neighbor] }

    self.class.response_data = [
      { 'message' => { 'content' => 'Spruce' } },
      { 'message' => { 'content' => 'YES' } }
    ]

    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke

    messages = Ollama.params_list.first[:messages]
    user_content = messages[1]['content']
    assert_includes user_content, 'Nearby tree names to avoid: Oak'
  end

  def test_verify_prompt_includes_tree_details
    @tree.define_singleton_method(:treedb_common_name) { 'Blue Gum' }
    @tree.define_singleton_method(:treedb_genus) { 'Eucalyptus' }
    @tree.define_singleton_method(:treedb_family) { 'Myrtaceae' }

    self.class.response_data = [
      { 'message' => { 'content' => 'Spruce' } },
      { 'message' => { 'content' => 'YES' } }
    ]

    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke

    verify_messages = Ollama.params_list[1][:messages]
    system_content = verify_messages[0]['content']

    assert_includes system_content, 'Blue Gum'
    assert_includes system_content, 'Eucalyptus'
    assert_includes system_content, 'Myrtaceae'
  end

  def test_followup_prompt_includes_rejection_reasons
    long_name = 'A' * 151
    self.class.response_data = [
      { 'message' => { 'content' => long_name } },
      { 'message' => { 'content' => 'Spruce' } },
      { 'message' => { 'content' => 'YES' } }
    ]

    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke

    follow_up = Ollama.params_list[1][:messages][1]['content']
    assert_includes follow_up, 'Previous failures'
    assert_includes follow_up, 'name too long or short'
  end
end

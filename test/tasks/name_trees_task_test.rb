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
    self.class.response_data = { 'message' => { 'content' => 'Fancy Tree' } }

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
          attr_accessor :call_count
        end

        attr_reader :last_chat_params

        def initialize(credentials:); end

        def chat(payload, **_opts)
          self.class.call_count = (self.class.call_count || 0) + 1
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
    assert_equal 'Qwen3:latest', @tree.attributes['llm_model']
  end

  def test_response_is_cleaned_of_think_tags
    self.class.response_data = [
      { 'message' => { 'content' => '<think>thinking</think>' } },
      { 'message' => { 'content' => "\n\nCrimson Cap" } }
    ]
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_equal 'Crimson Cap', @tree.attributes['name']
  end

  def test_skips_update_for_name_too_short
    self.class.response_data = { 'message' => { 'content' => 'A' } }
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_nil @tree.attributes['name']
  end

  def test_skips_update_for_name_too_long
    long_name = 'A' * 151
    self.class.response_data = { 'message' => { 'content' => long_name } }
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_nil @tree.attributes['name']
  end

  def test_retries_until_valid_name_received
    self.class.response_data = [
      { 'message' => { 'content' => 'A' } },
      { 'message' => { 'content' => 'B' } },
      { 'message' => { 'content' => 'Valid Name' } }
    ]
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_equal 'Valid Name', @tree.attributes['name']
    assert_equal 3, Ollama.call_count
  end

  def test_gives_up_after_three_failed_attempts
    long_name = 'A' * 151
    self.class.response_data = [
      { 'message' => { 'content' => long_name } },
      { 'message' => { 'content' => 'A' } },
      { 'message' => { 'content' => 'B' } }
    ]
    Rake.application['db:name_trees'].reenable
    Rake.application['db:name_trees'].invoke
    assert_nil @tree.attributes['name']
    assert_equal 3, Ollama.call_count
  end
end

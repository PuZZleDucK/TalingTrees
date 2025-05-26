# frozen_string_literal: true

require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'

class SystemPromptsTaskTest < Minitest::Test
  class << self
    attr_accessor :last_params

    def setup_tree_class
      Tree.class_eval do
        class << self
          attr_accessor :instances

          def find_each(&block)
            (instances || []).each(&block)
          end
        end
      end
    end
  end

  def setup
    self.class.setup_tree_class

    TreeRelationship.singleton_class.class_eval do
      attr_accessor :records

      def where(tree_id:, kind: nil)
        Array(records).select { |r| r.tree_id == tree_id }
      end
    end

    @tree = Tree.new(name: 'Oak', treedb_common_name: 'Blue Gum', llm_system_prompt: nil)
    @tree.define_singleton_method(:id) { 1 }
    class << @tree
      attr_reader :prompt

      def chat_relationship_prompt
        'rel info'
      end

      def update!(attrs)
        @prompt = attrs[:llm_system_prompt]
      end
    end

    Tree.instances = [@tree]

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
        attr_accessor :last_params, :response_data, :call_count, :params_list
      end

      def initialize(credentials:); end

      def chat(params)
        self.class.call_count = (self.class.call_count || 0) + 1
        self.class.last_params = params
        self.class.params_list ||= []
        self.class.params_list << params
        SystemPromptsTaskTest.last_params = params
        data = self.class.response_data
        if data.is_a?(Array)
          self.class.response_data = data[1..] || []
          data = data.first
        end
        data || { 'message' => { 'content' => 'You are to roleplay as Oak Blue Gum rel info' } }
      end
    end
    Object.const_set(:Ollama, stub_ollama)
    Ollama.call_count = 0

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/system_prompts.rake', __dir__)
  end

  def teardown
    Tree.instances = nil
    Object.send(:remove_const, :Ollama)
    Object.const_set(:Ollama, @previous_ollama) if @previous_ollama
    if @require_patched
      Kernel.module_eval do
        alias_method :require, :orig_require
        remove_method :orig_require
      end
    end
  end

  def test_sets_system_prompt
    Ollama.response_data = [
      { 'message' => { 'content' => 'You are to roleplay as Oak Blue Gum rel info' } },
      { 'message' => { 'content' => 8 } }
    ]
    Rake.application['db:system_prompts'].invoke
    assert_equal 'You are to roleplay as Oak Blue Gum rel info', @tree.prompt
    content = self.class.last_params[:messages][1]['content']
    assert_includes content, 'rel info'
    assert_includes content, 'Oak'
    assert_includes content, 'Blue Gum'
    assert_equal 2, Ollama.call_count
  end

  def test_think_tag_removed
    Ollama.response_data = [
      { 'message' => { 'content' => '<think>hmm</think>You are to roleplay as Oak Blue Gum rel info' } },
      { 'message' => { 'content' => 8 } }
    ]
    Rake.application['db:system_prompts'].reenable
    Rake.application['db:system_prompts'].invoke
    assert_equal 'You are to roleplay as Oak Blue Gum rel info', @tree.prompt
  end

  def test_retries_when_missing_intro
    Ollama.response_data = [
      { 'message' => { 'content' => 'Bad start' } },
      { 'message' => { 'content' => 'You are to roleplay as Oak Blue Gum rel info' } },
      { 'message' => { 'content' => 8 } }
    ]
    Rake.application['db:system_prompts'].reenable
    Rake.application['db:system_prompts'].invoke
    assert_equal 'You are to roleplay as Oak Blue Gum rel info', @tree.prompt
    assert_equal 3, Ollama.call_count
  end

  def test_retries_when_missing_name
    Ollama.response_data = [
      { 'message' => { 'content' => 'You are to roleplay as ??? Blue Gum rel info' } },
      { 'message' => { 'content' => 'You are to roleplay as Oak Blue Gum rel info' } },
      { 'message' => { 'content' => 8 } }
    ]
    Rake.application['db:system_prompts'].reenable
    Rake.application['db:system_prompts'].invoke
    assert_equal 'You are to roleplay as Oak Blue Gum rel info', @tree.prompt
    assert_equal 3, Ollama.call_count
  end

  def test_retries_when_missing_common_name
    Ollama.response_data = [
      { 'message' => { 'content' => 'You are to roleplay as Oak rel info' } },
      { 'message' => { 'content' => 'You are to roleplay as Oak Blue Gum rel info' } },
      { 'message' => { 'content' => 8 } }
    ]
    Rake.application['db:system_prompts'].reenable
    Rake.application['db:system_prompts'].invoke
    assert_equal 'You are to roleplay as Oak Blue Gum rel info', @tree.prompt
    assert_equal 3, Ollama.call_count
  end

  def test_retries_when_missing_relationships
    TreeRelationship.singleton_class.class_eval do
      attr_accessor :records
      def where(tree_id:, kind: nil)
        Array(records).select { |r| r.tree_id == tree_id }
      end
    end
    related = Tree.new(name: 'Piny', llm_system_prompt: nil)
    rel = TreeRelationship.new(tree_id: 1, related_tree: related, kind: 'neighbor')
    TreeRelationship.records = [rel]

    def @tree.chat_relationship_prompt
      'Neighbors include: Piny.'
    end

    Ollama.response_data = [
      { 'message' => { 'content' => 'You are to roleplay as Oak Blue Gum' } },
      { 'message' => { 'content' => 'You are to roleplay as Oak Blue Gum Piny' } },
      { 'message' => { 'content' => 8 } }
    ]
    Rake.application['db:system_prompts'].reenable
    Rake.application['db:system_prompts'].invoke
    assert_equal 'You are to roleplay as Oak Blue Gum Piny', @tree.prompt
    assert_equal 3, Ollama.call_count
  ensure
    TreeRelationship.records = nil
  end

  def test_followup_prompt_includes_rejection_reasons
    Ollama.response_data = [
      { 'message' => { 'content' => 'Bad start' } },
      { 'message' => { 'content' => 'You are to roleplay as ???' } },
      { 'message' => { 'content' => 'You are to roleplay as Oak Blue Gum rel info' } },
      { 'message' => { 'content' => 8 } }
    ]
    Rake.application['db:system_prompts'].reenable
    Rake.application['db:system_prompts'].invoke
    follow_up = Ollama.params_list[1][:messages][1]['content']
    assert_includes follow_up, 'Previous failures'
    assert_includes follow_up, 'missing intro'
  end

  def test_retries_when_rating_too_low
    Ollama.response_data = [
      { 'message' => { 'content' => 'You are to roleplay as Oak Blue Gum rel info' } },
      { 'message' => { 'content' => 4 } },
      { 'message' => { 'content' => 'You are to roleplay as Oak Blue Gum rel info' } },
      { 'message' => { 'content' => 8 } }
    ]
    Rake.application['db:system_prompts'].reenable
    Rake.application['db:system_prompts'].invoke
    assert_equal 'You are to roleplay as Oak Blue Gum rel info', @tree.prompt
    assert_equal 4, Ollama.call_count
  end
end

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

    @tree = Tree.new(name: 'Oak', treedb_common_name: 'Blue Gum')
    class << @tree
      attr_reader :prompt

      def chat_relationship_prompt
        'rel info'
      end

      def update!(attrs)
        @prompt = attrs[:llm_sustem_prompt]
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
        attr_accessor :last_params, :response_data
      end

      def initialize(credentials:); end

      def chat(params)
        SystemPromptsTaskTest.last_params = params
        data = self.class.response_data
        if data.is_a?(Array)
          self.class.response_data = data[1..] || []
          data = data.first
        end
        data || { 'message' => { 'content' => 'new prompt' } }
      end
    end
    Object.const_set(:Ollama, stub_ollama)

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
    Rake.application['db:system_prompts'].invoke
    assert_equal 'new prompt', @tree.prompt
    content = self.class.last_params[:messages][1]['content']
    assert_includes content, 'rel info'
    assert_includes content, 'Oak'
    assert_includes content, 'Blue Gum'
  end

  def test_think_tag_removed
    Ollama.response_data = [
      { 'message' => { 'content' => '<think>hmm</think>Final' } }
    ]
    Rake.application['db:system_prompts'].reenable
    Rake.application['db:system_prompts'].invoke
    assert_equal 'Final', @tree.prompt
  end
end

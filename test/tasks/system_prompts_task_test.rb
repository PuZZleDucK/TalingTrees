require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'

class SystemPromptsTaskTest < Minitest::Test
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

    @tree = Tree.new(name: 'Oak')
    def @tree.chat_relationship_prompt
      'rel info'
    end
    def @tree.update!(attrs)
      @prompt = attrs[:llm_sustem_prompt]
    end
    def @tree.prompt
      @prompt
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
        attr_accessor :last_params
      end

      def initialize(credentials:); end

      def chat(payload, **_opts)
        self.class.last_params = payload
        SystemPromptsTaskTest.response_data || { 'message' => { 'content' => 'Prompt' } }
      end
    end

    Object.const_set(:Ollama, stub_ollama)

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/system_prompts.rake', __dir__)
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

  def test_sets_system_prompt
    SystemPromptsTaskTest.response_data = { 'message' => { 'content' => 'the prompt' } }
    Rake.application['db:system_prompts'].invoke
    assert_equal 'You are Oak. the prompt', @tree.prompt
    messages = Ollama.last_params[:messages]
    assert_includes messages[1]['content'], 'Oak'
    assert_includes messages[1]['content'], 'rel info'
  end
end

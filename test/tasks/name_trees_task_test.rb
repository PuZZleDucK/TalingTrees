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
      attr_reader :last_chat_params
      def initialize(credentials:); end
      def chat(payload, **_opts)
        @last_chat_params = payload
        { 'message' => { 'content' => 'Fancy Tree' } }
      end
    end
    Object.const_set(:Ollama, stub_ollama)

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    Rake.application.rake_require('name_trees', ['lib/tasks'], [])
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
    Rake::Task['db:name_trees'].invoke
    assert_equal 'Fancy Tree', @tree.attributes['name']
    assert_equal 'Qwen3:latest', @tree.attributes['llm_model']
  end

  def test_think_tags_are_removed_from_response
    Object.send(:remove_const, :Ollama)
    custom_stub = Class.new do
      def initialize(credentials:); end
      def chat(_payload, **_opts)
        { 'message' => { 'content' => '<think>processing</think>River Rover' } }
      end
    end
    Object.const_set(:Ollama, custom_stub)

    Rake::Task['db:name_trees'].reenable
    Rake::Task['db:name_trees'].invoke

    assert_equal 'River Rover', @tree.attributes['name']
  end
end

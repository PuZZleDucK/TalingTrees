# frozen_string_literal: true

require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'

class SystemPromptsTaskTest < Minitest::Test
  class << self
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

    @tree = Tree.new(name: 'Oak')
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

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/system_prompts.rake', __dir__)
  end

  def teardown
    Tree.instances = nil
  end

  def test_sets_system_prompt
    Rake.application['db:system_prompts'].invoke
    assert_includes @tree.prompt, 'rel info'
    assert_includes @tree.prompt.downcase, 'talking tree'
  end
end

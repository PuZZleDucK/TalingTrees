# frozen_string_literal: true

require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'

class OllamaSetupTaskTest < Minitest::Test
  class << self
    attr_accessor :system_calls
  end

  def setup
    self.class.system_calls = []

    Kernel.module_eval do
      alias_method :orig_system, :system
      def system(*args)
        OllamaSetupTaskTest.system_calls << args
        true
      end
    end
    @system_patched = true

    @previous_env = {
      'LLM_NAMING_MODEL' => ENV['LLM_NAMING_MODEL'],
      'LLM_NAMING_VERIFY_MODEL' => ENV['LLM_NAMING_VERIFY_MODEL'],
      'LLM_CHAT_MODEL' => ENV['LLM_CHAT_MODEL'],
      'RAILS_ENV' => ENV['RAILS_ENV']
    }
    ENV['RAILS_ENV'] = 'test'
    ENV['LLM_NAMING_MODEL'] = 'model1'
    ENV['LLM_NAMING_VERIFY_MODEL'] = 'model3'
    ENV['LLM_CHAT_MODEL'] = 'model2'

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/ollama.rake', __dir__)
  end

  def teardown
    @previous_env.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end

    if @system_patched
      Kernel.module_eval do
        alias_method :system, :orig_system
        remove_method :orig_system
      end
    end
  end

  def test_pulls_unique_models
    Rake.application['ollama:setup'].invoke

    assert_includes self.class.system_calls, ['bash', '-c', 'curl -fsSL https://ollama.ai/install.sh | sh']
    assert_includes self.class.system_calls, %w[ollama pull model1]
    assert_includes self.class.system_calls, %w[ollama pull model2]
    assert_includes self.class.system_calls, %w[ollama pull model3]
    assert_equal 4, self.class.system_calls.length
  end
end

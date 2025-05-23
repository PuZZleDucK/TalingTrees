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

    YAML.singleton_class.class_eval do
      alias_method :orig_load_file, :load_file
      def load_file(_path, **_opts)
        { 'development' => {
            'naming_model' => 'model1',
            'verify_model' => 'model1',
            'final_model' => 'model2'
        } }
      end
    end
    @yaml_patched = true

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/ollama.rake', __dir__)
  end

  def teardown
    if @system_patched
      Kernel.module_eval do
        alias_method :system, :orig_system
        remove_method :orig_system
      end
    end

    if @yaml_patched
      YAML.singleton_class.class_eval do
        remove_method :load_file
        alias_method :load_file, :orig_load_file
        remove_method :orig_load_file
      end
    end
  end

  def test_pulls_unique_models
    Rake.application['ollama:setup'].invoke

    assert_includes self.class.system_calls, ['bash', '-c', 'curl -fsSL https://ollama.ai/install.sh | sh']
    assert_includes self.class.system_calls, ['ollama', 'pull', 'model1']
    assert_includes self.class.system_calls, ['ollama', 'pull', 'model2']
    assert_equal 3, self.class.system_calls.length
  end
end

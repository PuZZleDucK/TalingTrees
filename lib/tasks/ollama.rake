# frozen_string_literal: true

namespace :ollama do
  desc 'Install Ollama and download configured models'
  task :setup do
    require 'yaml'

    puts 'Installing Ollama...'
    system('bash', '-c', 'curl -fsSL https://ollama.ai/install.sh | sh')

    env = ENV['RAILS_ENV'] || 'development'
    config_path = File.expand_path('../../config/llm.yml', __dir__)
    config = YAML.load_file(config_path, aliases: true)
    env_config = config[env] || {}

    models = [env_config['naming_model'], env_config['verify_model'], env_config['final_model']].compact.uniq
    models.each do |model|
      puts "Pulling #{model}"
      system('ollama', 'pull', model)
    end
  end
end

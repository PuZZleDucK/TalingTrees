# frozen_string_literal: true

require_relative 'tree_namer'

module Tasks
  # Generates names for trees using large language models.
  class NameTrees
    def run
      require 'ollama-ai'
      require 'yaml'
      require 'erb'

      config = load_config
      puts "Naming config models: naming=#{config['naming_model']} verify=#{config['verify_model']} final=#{config['final_model']}"
      address = ENV.fetch('OLLAMA_URL', 'http://localhost:11434')
      puts "Using Ollama endpoint: #{address}"
      client = Ollama.new(credentials: { address: address })
      namer = TreeNamer.new(client, config)

      Tree.find_each { |tree| namer.name_tree(tree) }
    end

    private
    def load_config
      env = ENV['RAILS_ENV'] || 'development'
      config_path = File.expand_path('../config/llm.yml', __dir__)
      raw_config = ERB.new(File.read(config_path)).result
      YAML.safe_load(raw_config, permitted_classes: [], permitted_symbols: [], aliases: true)[env]
    end
  end
end

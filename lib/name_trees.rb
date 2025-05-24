# frozen_string_literal: true

require_relative 'tree_namer'

module Tasks
  # Generates names for trees using large language models.
  class NameTrees
    def run
      require 'ollama-ai'
      require 'yaml'

      config = load_config
      client = Ollama.new(credentials: { address: ENV.fetch('OLLAMA_URL', 'http://0.0.0.0:11434') })
      namer = TreeNamer.new(client, config)

      Tree.find_each { |tree| namer.name_tree(tree) }
    end

    private

    def load_config
      env = ENV['RAILS_ENV'] || 'development'
      config_path = File.expand_path('../config/llm.yml', __dir__)
      YAML.load_file(config_path, aliases: true)[env]
    end
  end
end

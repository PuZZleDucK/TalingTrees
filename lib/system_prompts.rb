# frozen_string_literal: true

module Tasks
  # Generates system prompts for trees using an LLM
  class SystemPrompts
    def run
      require 'ollama-ai'
      require 'yaml'

      config = load_config
      client = Ollama.new(credentials: { address: ENV.fetch('OLLAMA_URL', 'http://0.0.0.0:11434') })
      generator = PromptGenerator.new(client, config)

      Tree.find_each do |tree|
        identifier = tree.respond_to?(:id) ? "##{tree.id}" : tree.to_s
        puts "Generating system prompt for tree #{identifier}"

        prompt = generator.generate(tree)
        puts "Final prompt:\n#{prompt}"

        tree.update!(llm_sustem_prompt: prompt)
        puts "Updated tree #{identifier}"
        puts
      end
    end

    private

    def load_config
      env = ENV['RAILS_ENV'] || 'development'
      config_path = File.expand_path('../config/llm.yml', __dir__)
      YAML.load_file(config_path, aliases: true)[env]
    end
  end

  # Helper object to build a prompt for a single tree
  class PromptGenerator
    def initialize(client, config)
      @client = client
      @config = config
    end

    def generate(tree)
      messages = [
        { 'role' => 'system', 'content' => @config['system_prompt_prompt'] },
        { 'role' => 'user', 'content' => facts_for(tree) }
      ]
      response = @client.chat({ model: @config['system_prompt_model'], messages: messages })
      content = if response.is_a?(Array)
                  response.map { |r| r.dig('message', 'content') }.join
                else
                  response.dig('message', 'content')
                end.to_s
      clean_prompt(content)
    end

    private

    def clean_prompt(content)
      content.to_s.gsub(%r{<think(ing)?[^>]*>.*?</think(ing)?>}mi, '').strip
    end

    def facts_for(tree)
      lines = []
      lines << "Name: #{tree.name}" if tree.respond_to?(:name)
      if tree.respond_to?(:treedb_common_name) && tree.treedb_common_name.present?
        lines << "Species: #{tree.treedb_common_name}"
      end
      rel_prompt = tree.chat_relationship_prompt.to_s
      lines << rel_prompt unless rel_prompt.empty?
      lines.join("\n")
    end
  end
end

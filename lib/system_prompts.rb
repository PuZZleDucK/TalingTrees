# frozen_string_literal: true

require_relative 'tree_namer'

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
        next if tree.llm_sustem_prompt.present?

        puts ''
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
      attempt = 0
      reasons = []
      loop do
        attempt += 1
        user_content = facts_for(tree)
        user_content += "\nPrevious failures: #{reasons.join('; ')}" if reasons.any?
        messages = [
          { 'role' => 'system', 'content' => @config['system_prompt_prompt'] },
          { 'role' => 'user', 'content' => user_content }
        ]
        response = @client.chat({ model: @config['system_prompt_model'], messages: messages })
        content = if response.is_a?(Array)
                    response.map { |r| r.dig('message', 'content') }.join
                  else
                    response.dig('message', 'content')
                  end.to_s
        prompt = clean_prompt(content)
        next unless valid_prompt?(prompt, tree, reasons)
        break prompt if verify_prompt(prompt, reasons)
      end
    end

    private

    def clean_prompt(content)
      content.to_s.gsub(%r{<think(ing)?[^>]*>.*?</think(ing)?>}mi, '').strip
    end

    def facts_for(tree)
      details = TreeFacts.new(tree).facts
      rel_prompt = tree.chat_relationship_prompt.to_s
      [details, rel_prompt].reject { |l| l.to_s.strip.empty? }.join("\n")
    end

    def valid_prompt?(prompt, tree, reasons)
      unless prompt.start_with?('You are to roleplay as')
        puts "Rejected prompt due to missing intro: #{prompt.inspect}"
        puts ''
        reasons << 'missing intro'
        return false
      end

      name = tree.respond_to?(:name) ? tree.name.to_s.strip : ''
      unless name.empty? || prompt.include?(name)
        puts "Rejected prompt due to missing name: #{prompt.inspect}"
        reasons << "missing name: '#{name}'"
        return false
      end

      common = if tree.respond_to?(:treedb_common_name)
                 tree.treedb_common_name.to_s.strip
               else
                 ''
               end
      unless common.empty? || prompt.downcase.include?(common.downcase)
        puts "Rejected prompt due to missing common name: #{prompt.inspect}"
        reasons << 'missing common name'
        return false
      end

      rel_names = if tree.respond_to?(:id)
                    rels = if tree.respond_to?(:tree_relationships) && tree.tree_relationships.loaded?
                             tree.tree_relationships
                           elsif TreeRelationship.respond_to?(:where)
                             TreeRelationship.where(tree_id: tree.id)
                           elsif TreeRelationship.respond_to?(:records)
                             Array(TreeRelationship.records).select { |r| r[:tree_id] == tree.id }
                           else
                             []
                           end
                    rels.filter_map do |rel|
                      related = rel.respond_to?(:related_tree) ? rel.related_tree : rel[:related_tree]
                      related&.name.to_s.strip
                    end.reject(&:empty?).uniq
                  else
                    []
                  end
      unless rel_names.empty? || rel_names.any? { |n| prompt.downcase.include?(n.downcase) }
        puts "Rejected prompt due to missing relationships: #{prompt.inspect}"
        reasons << 'missing relationships'
        return false
      end

      true
    end

    def verify_prompt(prompt, reasons)
      verify_messages = [
        { 'role' => 'system', 'content' => @config['system_prompt_verify_prompt_template'] },
        { 'role' => 'user', 'content' => prompt }
      ]
      verify = @client.chat({ model: @config['system_prompt_verify_model'], messages: verify_messages })
      verify_content = if verify.is_a?(Array)
                         verify.map { |r| r.dig('message', 'content') }.join
                       else
                         verify.dig('message', 'content')
                       end.to_s.strip
      rating_text = verify_content[/\d+(?:\.\d+)?/]
      rating = rating_text ? rating_text.to_f : 0.0

      if rating >= @config['system_prompt_rating_threshold'].to_f
        true
      else
        puts "Rejected prompt after rating #{rating}: #{prompt.inspect}"
        reasons << 'failed rating'
        false
      end
    end
  end
end

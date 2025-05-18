namespace :db do
  desc 'Assign fun, kid-friendly names to trees using local Ollama'
  task name_trees: :environment do
    require 'ollama-ai'

    system_prompt = 'You are a creative and colorful individual who had a deep understanding of trees and the attitudes of school children. Your job is to take factual information about a tree and give it a fun name that kids will like. You must only respond with the name you think the tree should have. Do not quote or decorate or introduce the name in any way you must only respond with the name.'

    client = Ollama.new(credentials: { address: ENV.fetch('OLLAMA_URL', 'http://localhost:11434') })

    Tree.find_each do |tree|
      identifier = tree.respond_to?(:id) ? "##{tree.id}" : tree.to_s
      puts "Naming tree #{identifier}"

      facts = tree.attributes
                .except('llm_model', 'llm_sustem_prompt', 'created_at', 'updated_at')
                .map { |k, v| v.nil? || v.to_s.strip.empty? ? nil : "#{k}: #{v}" }
                .compact
                .join("\n")

      puts "Facts:\n#{facts}"

      messages = [
        { 'role' => 'system', 'content' => system_prompt },
        { 'role' => 'user', 'content' => facts }
      ]

      response = client.chat({ model: 'Qwen3:latest', messages: messages })
      puts "Response: #{response.inspect}"

      content = if response.is_a?(Array)
                   response.map { |r| r.dig('message', 'content') }.join
                 else
                   response.dig('message', 'content')
                 end.to_s
      cleaned = content
                .gsub(/<thinking>.*?<\/thinking>/mi, '')
                .gsub(/\[.*?\]/m, '')
                .gsub(/"/, '')
                .strip

      puts "Cleaned name: #{cleaned}"

      tree.update!(name: cleaned, llm_model: 'Qwen3:latest', llm_sustem_prompt: system_prompt)
      puts "Updated tree #{identifier}"
    end
  end
end

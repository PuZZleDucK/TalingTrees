namespace :db do
  desc 'Generate unique system prompts for each tree using Ollama'
  task system_prompts: :environment do
    require 'ollama-ai'

    instruction = <<~PROMPT.strip
      You write short system prompts that will be used to roleplay as talking trees.
      Each prompt should be written in the first person and encourage playful conversation.
      The tree should know its own name and hint that it knows other trees but only reveal their names when asked.
    PROMPT

    client = Ollama.new(credentials: { address: ENV.fetch('OLLAMA_URL', 'http://localhost:11434') })

    Tree.find_each do |tree|
      info = "Tree name: #{tree.name}"
      rel_prompt = tree.chat_relationship_prompt.to_s
      info += "\n" + rel_prompt unless rel_prompt.empty?

      messages = [
        { 'role' => 'system', 'content' => instruction },
        { 'role' => 'user', 'content' => info }
      ]

      puts "LLM prompt for #{tree.name}:"
      messages.each { |m| puts "#{m['role']}: #{m['content']}" }

      response = client.chat({ model: 'Qwen3:0.6b', messages: messages })
      content = if response.is_a?(Array)
                  response.map { |r| r.dig('message', 'content') }.join
                else
                  response.dig('message', 'content')
                end.to_s.strip

      prompt = "You are #{tree.name}. #{content}"

      tree.update!(llm_sustem_prompt: prompt)

      puts "Generated system prompt for #{tree.name}:"
      puts prompt
      puts
    end
  end
end

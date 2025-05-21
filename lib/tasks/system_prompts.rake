namespace :db do
  desc 'Generate unique system prompts for trees using Ollama'
  task system_prompts: :environment do
    require 'ollama-ai'

    generator_prompt = 'Write a short system prompt for a playful talking tree NPC. Mention that the tree knows other trees but only reveal their names when asked. Include any relationship info provided and respond only with the prompt.'

    client = Ollama.new(credentials: { address: ENV.fetch('OLLAMA_URL', 'http://localhost:11434') })

    Tree.find_each do |tree|
      user_content = tree.chat_relationship_prompt.to_s
      species = tree.respond_to?(:treedb_common_name) ? tree.treedb_common_name.to_s.strip : ''
      user_content = "Species: #{species}\n#{user_content}".strip

      messages = [
        { 'role' => 'system', 'content' => generator_prompt },
        { 'role' => 'user', 'content' => user_content }
      ]

      response = client.chat({ model: 'Qwen3:0.6b', messages: messages })
      content = if response.is_a?(Array)
                   response.map { |r| r.dig('message', 'content') }.join
                 else
                   response.dig('message', 'content')
                 end.to_s
      cleaned = content.gsub(/<think(ing)?[^>]*>.*?<\/think(ing)?>/mi, '').strip
      tree.update!(llm_sustem_prompt: cleaned, llm_model: 'Qwen3:latest')
    end
  end
end

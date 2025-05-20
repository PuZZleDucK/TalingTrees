namespace :db do
  desc 'Assign fun, kid-friendly names to trees using local Ollama'
  task name_trees: :environment do
    require 'ollama-ai'

    system_prompt = 'You are a creative and colorful individual who had a deep understanding of trees and the attitudes of school children. Your job is to take factual information about a tree and give it a fun personal name that kids will like. Do not just use the trees common name. You must only respond with the name you think the tree should have. Do not quote or decorate or introduce the name in any way you must only respond with the name.'

    client = Ollama.new(credentials: { address: ENV.fetch('OLLAMA_URL', 'http://localhost:11434') })

    verify_prompt = 'You approve tree names. Tree names should not just be the species or common name of the tree. Tree names should have some personality. Respond with YES if the provided text is a suitable name, otherwise respond with NO.'

    Tree.find_each do |tree|
      identifier = tree.respond_to?(:id) ? "##{tree.id}" : tree.to_s
      puts "Naming tree #{identifier}"

      facts = tree.attributes
                .except('id', 'treedb_com_id', 'llm_model', 'llm_sustem_prompt', 'created_at', 'updated_at')
                .map { |k, v| v.nil? || v.to_s.strip.empty? ? nil : "#{k}: #{v}" }
                .compact
                .join("\n")

      puts "Facts:\n#{facts}"

      messages = [
        { 'role' => 'system', 'content' => system_prompt },
        { 'role' => 'user', 'content' => facts }
      ]

      attempt = 0
      cleaned = nil
      while attempt < 3
        attempt += 1

        response = client.chat({ model: 'Qwen3:0.6b', messages: messages })

        content = if response.is_a?(Array)
                     response.map { |r| r.dig('message', 'content') }.join
                   else
                     response.dig('message', 'content')
                   end.to_s
        cleaned = content
                  .gsub(/<think(ing)?[^>]*>.*?<\/think(ing)?>/mi, '')
                  .gsub(/\[.*?\]/m, '')
                  .gsub(/"/, '')
                  .strip

        if cleaned.length > 150 || cleaned.length < 3
          puts "Rejected name due to length: #{cleaned.inspect}"
          cleaned = nil
        else
          verify_messages = [
            { 'role' => 'system', 'content' => verify_prompt },
            { 'role' => 'user', 'content' => cleaned }
          ]
          verify = client.chat({ model: 'Qwen3:0.6b', messages: verify_messages })
          verify_content = if verify.is_a?(Array)
                             verify.map { |r| r.dig('message', 'content') }.join
                           else
                             verify.dig('message', 'content')
                           end.to_s.strip
          if verify_content =~ /^y(es)?/i
            break
          else
            puts "Rejected name after verification: #{cleaned.inspect}"
            cleaned = nil
          end
        end
      end

      unless cleaned
        puts "Failed to generate valid name after #{attempt} attempts"
        puts
        next
      end

      puts "Cleaned name: #{cleaned}"

      tree.update!(name: cleaned, llm_model: 'Qwen3:latest', llm_sustem_prompt: system_prompt)
      puts "Updated tree #{identifier}"
      puts
    end
  end
end

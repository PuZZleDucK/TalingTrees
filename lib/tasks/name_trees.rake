namespace :db do
  desc 'Assign fun, kid-friendly names to trees using local Ollama'
  task name_trees: :environment do
    require 'ollama-ai'

    system_prompt = 'You are a creative and colorful individual who had a deep understanding of trees and the attitudes of school children. Your job is to take factual information about a tree and give it a fun personal name that kids will like. It should be the kind of name that could be used to identify the tree by its friends. Do not just use the trees common_name or a re-ordering of the common_name You should not even include the common_name in the personal name at all, but rather use it as inspiration and a jumping off point. The name should sound like a fantasy character name. You must only respond with the name you think the tree should have. Do not quote or decorate or introduce the name in any way you must only respond with the name.'

    client = Ollama.new(credentials: { address: ENV.fetch('OLLAMA_URL', 'http://localhost:11434') })

    verify_prompt_template = 'Your job is to approve tree names if they are good valid names. Tree names should not just be the species or common_name of the tree or a re-ordering of the common_name. Tree names should have some personality. The tree you are checking has the common name "%{common_name}", the genus "%{genus}" and the family "%{family}". Respond with YES if the provided text is a suitable name, otherwise respond with NO. Do not quote or decorate or introduce or explain the response in any way. You must only respond with YES or NO.'

    Tree.find_each do |tree|
      name_val = if tree.respond_to?(:attributes)
                    tree.attributes['name']
                  elsif tree.respond_to?(:name)
                    tree.name
                  end
      next if name_val && !name_val.to_s.strip.empty?

      identifier = tree.respond_to?(:id) ? "##{tree.id}" : tree.to_s
      puts "Naming tree #{identifier}"

      facts = tree.attributes
                .except('id', 'treedb_com_id', 'llm_model', 'llm_sustem_prompt', 'created_at', 'updated_at')
                .map { |k, v| v.nil? || v.to_s.strip.empty? ? nil : "#{k}: #{v}" }
                .compact
                .join("\n")

      neighbor_names = if tree.respond_to?(:treedb_lat) && tree.respond_to?(:treedb_long)
                         tree.neighbors_within(50).map { |n| n.name.to_s.strip }
                                              .reject(&:empty?)
                       else
                         []
                       end
      facts += "\nNearby tree names to avoid: #{neighbor_names.join(', ')}" unless neighbor_names.empty?

      puts "Facts:\n#{facts}"

      attempt = 0
      cleaned = nil
      reasons = []
      while attempt < 3
        attempt += 1

        user_content = facts.dup
        user_content += "\nPrevious failures: #{reasons.join('; ')}" if reasons.any?

        messages = [
          { 'role' => 'system', 'content' => system_prompt },
          { 'role' => 'user', 'content' => user_content }
        ]

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
          reasons << 'name too long or short'
          cleaned = nil
        else
          verify_prompt = format(
            verify_prompt_template,
            common_name: tree.respond_to?(:treedb_common_name) ? tree.treedb_common_name.to_s : '',
            genus: tree.respond_to?(:treedb_genus) ? tree.treedb_genus.to_s : '',
            family: tree.respond_to?(:treedb_family) ? tree.treedb_family.to_s : ''
          )
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
            neighbor_names = if tree.respond_to?(:treedb_lat) && tree.respond_to?(:treedb_long)
                               tree.neighbors_within(50)
                                   .map { |n| n.name.to_s.downcase.strip }
                                   .reject(&:empty?)
                             else
                               []
                             end
            if neighbor_names.include?(cleaned.downcase)
              puts "Rejected duplicate name within 50m: #{cleaned.inspect}"
              reasons << 'duplicate within 50m'
              cleaned = nil
            else
              break
            end
          else
            puts "Rejected name after verification: #{cleaned.inspect}"
            reasons << 'failed verification'
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

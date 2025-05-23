module Tasks
  class NameTrees
    def run
      require 'ollama-ai'
      require 'yaml'

      env = ENV['RAILS_ENV'] || 'development'
      config_path = File.expand_path('../config/llm.yml', __dir__)
      llm_config = YAML.load_file(config_path, aliases: true)[env]

      system_prompt = llm_config['naming_prompt']
      verify_prompt_template = llm_config['verify_prompt_template']
      naming_model = llm_config['naming_model']
      verify_model = llm_config['verify_model']
      final_model = llm_config['final_model']

      client = Ollama.new(credentials: { address: ENV.fetch('OLLAMA_URL', 'http://localhost:11434') })

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
        loop do
          attempt += 1

          user_content = facts.dup
          user_content += "\nPrevious failures: #{reasons.join('; ')}" if reasons.any?

          messages = [
            { 'role' => 'system', 'content' => system_prompt },
            { 'role' => 'user', 'content' => user_content }
          ]

          response = client.chat({ model: naming_model, messages: messages })

          content = if response.is_a?(Array)
                      response.map { |r| r.dig('message', 'content') }.join
                    else
                      response.dig('message', 'content')
                    end.to_s
          cleaned = content
                    .gsub(%r{<think(ing)?[^>]*>.*?</think(ing)?>}mi, '')
                    .gsub(/\[.*?\]/m, '')
                    .gsub('"', '')
                    .strip

          if cleaned =~ /[^\w\s,-]/
            puts "Rejected name due to punctuation: #{cleaned.inspect}"
            reasons << 'invalid punctuation'
          elsif cleaned.length > 150 || cleaned.length < 3
            puts "Rejected name due to length: #{cleaned.inspect}"
            reasons << 'name too long or short'
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
            verify = client.chat({ model: verify_model, messages: verify_messages })
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
              break unless neighbor_names.include?(cleaned.downcase)

              puts "Rejected duplicate name within 50m: #{cleaned.inspect}"
              reasons << 'duplicate within 50m'
            else
              puts "Rejected name after verification: #{cleaned.inspect}"
              reasons << 'failed verification'
            end
          end
          cleaned = nil
        end

        unless cleaned
          puts "Failed to generate valid name after #{attempt} attempts"
          puts
          next
        end

        puts "Cleaned name: #{cleaned}"

        tree.update!(name: cleaned, llm_model: final_model, llm_sustem_prompt: system_prompt)
        puts "Updated tree #{identifier}"
        puts
      end
    end
  end
end

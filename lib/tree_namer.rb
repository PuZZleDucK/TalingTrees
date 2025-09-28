# frozen_string_literal: true

module Tasks
  # Handles generating names for trees via LLM
  class TreeNamer
    def initialize(client, config)
      @client = client
      @config = config
    end

    def name_tree(tree)
      return unless name_blank?(tree)

      identifier = tree.respond_to?(:id) ? "##{tree.id}" : tree.to_s
      puts "Naming tree #{identifier}"

      facts = TreeFacts.new(tree).facts
      puts "Facts:\n#{facts}"

      generator = TreeNameGenerator.new(@client, @config)
      name = generator.generate(tree, facts)
      unless name
        puts 'Failed to generate valid name'
        puts
        return
      end

      name = name.split.map(&:capitalize).join(' ')

      puts "Cleaned name: #{name}"
      tree.update!(name: name, llm_model: @config['final_model'])
      puts "Updated tree #{identifier}"
      puts
    end

    private

    def name_blank?(tree)
      val = if tree.respond_to?(:attributes)
              tree.attributes['name']
            elsif tree.respond_to?(:name)
              tree.name
            end
      val.to_s.strip.empty?
    end
  end

  # Collects relevant facts about a tree
  class TreeFacts
    def initialize(tree)
      @tree = tree
    end

    def facts
      base = @tree.attributes
                  .except('id', 'treedb_com_id', 'llm_model', 'llm_system_prompt', 'created_at', 'updated_at')
                  .map { |k, v| v.nil? || v.to_s.strip.empty? ? nil : "#{k}: #{v}" }
                  .compact.join("\n")
      neighbor_names = if @tree.respond_to?(:treedb_lat) && @tree.respond_to?(:treedb_long)
                         @tree.neighbors_within(100).map { |n| n.name.to_s.strip }.reject(&:empty?)
                       else
                         []
                       end
      base += "\nNearby tree names to avoid: #{neighbor_names.join(', ')}" unless neighbor_names.empty?

      suburb = if defined?(Suburb) && @tree.respond_to?(:treedb_lat) && @tree.respond_to?(:treedb_long)
                 lat = @tree.treedb_lat
                 lon = @tree.treedb_long
                 if lat && lon
                   begin
                     Suburb.find_containing(lat, lon)
                   rescue StandardError
                     nil
                   end
                 end
               end
      if suburb&.respond_to?(:name)
        name = suburb.name.to_s.strip
        unless name.empty?
          base += "\nsuburb: #{name}"
          if suburb.respond_to?(:tree_count) && suburb.tree_count
            other = [suburb.tree_count.to_i - 1, 0].max
            base += "\nother_trees_in_suburb: #{other}"
          end
          same_species = same_species_in_suburb(suburb)
          base += "\nsame_species_in_suburb: #{same_species}" if same_species
        end
      end

      landmark_details = landmarks_with_distances
      if landmark_details.any?
        nearest = landmark_details.min_by { |entry| entry[:distance] }
        base += "\nclosest_landmark: #{nearest[:name]} (~#{nearest[:distance].round}m)"

        close_landmarks = landmark_details.select { |entry| entry[:distance] <= 50 }
        if close_landmarks.any?
          summary = close_landmarks.map { |entry| "#{entry[:name]} (~#{entry[:distance].round}m)" }.join(', ')
          base += "\nlandmarks_within_50m: #{summary}"
        end
      end

      base
    end

    private

    def same_species_in_suburb(suburb)
      return unless @tree.respond_to?(:treedb_common_name)

      species = @tree.treedb_common_name.to_s.strip
      return if species.empty?

      trees = if Tree.respond_to?(:where)
                relation = Tree.where(treedb_common_name: species).where.not(treedb_lat: nil, treedb_long: nil)
                relation = relation.where.not(id: @tree.id) if @tree.respond_to?(:id)
                relation
              elsif Tree.respond_to?(:records)
                Array(Tree.records)
              else
                []
              end
      trees = trees.to_a if trees.respond_to?(:to_a)

      count = 0
      trees.each do |candidate|
        candidate_species = candidate.respond_to?(:treedb_common_name) ? candidate.treedb_common_name : candidate[:treedb_common_name]
        next unless candidate_species.to_s.strip.casecmp?(species)

        lat = candidate.respond_to?(:treedb_lat) ? candidate.treedb_lat : candidate[:treedb_lat]
        lon = candidate.respond_to?(:treedb_long) ? candidate.treedb_long : candidate[:treedb_long]
        next if lat.nil? || lon.nil?
        next if same_tree?(candidate)

        begin
          count += 1 if suburb.contains_point?(lat.to_f, lon.to_f)
        rescue StandardError
          next
        end
      end

      count
    end

    def same_tree?(candidate)
      return true if candidate.equal?(@tree)

      candidate_id = candidate.respond_to?(:id) ? candidate.id : candidate[:id]
      tree_id = @tree.respond_to?(:id) ? @tree.id : @tree.attributes&.dig('id')
      candidate_id && tree_id && candidate_id == tree_id
    end

    def landmarks_with_distances
      lat = coordinate_for(@tree, :treedb_lat)
      lon = coordinate_for(@tree, :treedb_long)
      return [] unless lat && lon

      points = points_of_interest
      return [] if points.empty?

      points.filter_map do |poi|
        poi_lat = coordinate_for(poi, :centroid_lat)
        poi_lon = coordinate_for(poi, :centroid_long)
        next unless poi_lat && poi_lon

        distance = Tree.haversine_distance(lat, lon, poi_lat, poi_lon)
        name = value_for(poi, :site_name).to_s.strip
        next if name.empty?

        { name: name, distance: distance }
      end
    end

    def points_of_interest
      return [] unless defined?(PointOfInterest)

      scope = if PointOfInterest.respond_to?(:all)
                PointOfInterest.all
              elsif PointOfInterest.respond_to?(:records)
                PointOfInterest.records
              else
                []
              end

      scope = scope.to_a if scope.respond_to?(:to_a)
      Array(scope)
    rescue StandardError
      []
    end

    def coordinate_for(record, attr)
      value = value_for(record, attr)
      return unless value

      Float(value)
    rescue ArgumentError, TypeError
      nil
    end

    def value_for(record, attr)
      if record.respond_to?(attr)
        record.public_send(attr)
      elsif record.respond_to?(:[])
        record[attr] || record[attr.to_s]
      end
    end
  end

  # Generates and verifies potential names
  class TreeNameGenerator
    def initialize(client, config)
      @client = client
      @config = config
    end

    def generate(tree, facts)
      attempt = 0
      reasons = []
      loop do
        attempt += 1
        user_content = facts.dup
        user_content += "\nPrevious failures: #{reasons.join('; ')}" if reasons.any?
        messages = [
          { 'role' => 'system', 'content' => @config['naming_prompt'] },
          { 'role' => 'user', 'content' => user_content }
        ]
        response = @client.chat({ model: @config['naming_model'], messages: messages })
        content = if response.is_a?(Array)
                    response.map { |r| r.dig('message', 'content') }.join
                  else
                    response.dig('message', 'content')
                  end.to_s
        name = clean_name(content)
        next unless valid_format?(name, tree, reasons)
        break name if verify_name(name, tree, reasons)
      end
    end

  private

    def clean_name(content)
      content.gsub(%r{<think(ing)?[^>]*>.*?</think(ing)?>}mi, '')
             .gsub(/\[.*?\]/m, '')
             .gsub('"', '')
             .strip
    end

    BANNED_WORDS_REGEX = /\b(tree|forest|grove)\b/i
    private_constant :BANNED_WORDS_REGEX

    def valid_format?(name, tree, reasons)
      if name =~ /[^\w\s-]/
        puts "Rejected name due to punctuation: #{name.inspect}"
        reasons << 'invalid punctuation'
        false
      elsif name.length > 150 || name.length < 3
        puts "Rejected name due to length: #{name.inspect}"
        reasons << 'name too long or short'
        false
      elsif name =~ /\d/
        puts "Rejected name due to digits: #{name.inspect}"
        reasons << 'contains digits'
        false
      elsif tree.respond_to?(:treedb_common_name) &&
            tree.treedb_common_name.to_s.strip != '' &&
            name.downcase.include?(tree.treedb_common_name.to_s.downcase)
        puts "Rejected name due to common name: #{name.inspect}"
        reasons << 'contains common name'
        false
      elsif name =~ BANNED_WORDS_REGEX
        puts "Rejected name due to banned word: #{name.inspect}"
        reasons << 'contains banned word'
        false
      else
        true
      end
    end

    def verify_name(name, tree, reasons)
      verify_prompt = format(
        @config['verify_prompt_template'],
        common_name: tree.respond_to?(:treedb_common_name) ? tree.treedb_common_name.to_s : '',
        genus: tree.respond_to?(:treedb_genus) ? tree.treedb_genus.to_s : '',
        family: tree.respond_to?(:treedb_family) ? tree.treedb_family.to_s : ''
      )
      verify_messages = [
        { 'role' => 'system', 'content' => verify_prompt },
        { 'role' => 'user', 'content' => name }
      ]
      verify = @client.chat({ model: @config['verify_model'], messages: verify_messages })
      verify_content = if verify.is_a?(Array)
                         verify.map { |r| r.dig('message', 'content') }.join
                       else
                         verify.dig('message', 'content')
                       end.to_s.strip

      rating_text = verify_content[/\d+(?:\.\d+)?/]
      rating = rating_text ? rating_text.to_f : 0.0

      if rating >= @config['rating_threshold'].to_f
        return false if duplicate_name?(name, tree, reasons)

        true
      else
        puts "Rejected name after rating #{rating}: #{name.inspect}"
        reasons << 'failed rating'
        false
      end
    end

    def duplicate_name?(name, tree, reasons)
      neighbor_names = if tree.respond_to?(:treedb_lat) && tree.respond_to?(:treedb_long)
                         tree.neighbors_within(100).map { |n| n.name.to_s.downcase.strip }.reject(&:empty?)
                       else
                         []
                       end
      return false unless neighbor_names.include?(name.downcase)

      puts "Rejected duplicate name within 100m: #{name.inspect}"
      reasons << 'duplicate within 100m'
      true
    end
  end
end

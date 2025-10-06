# frozen_string_literal: true

module Tasks
  # Builds relationships between tree records for recommendations.
  class RelationshipBuilder
    def initialize(radius: 20)
      @radius = radius
    end

    def run
      trees = Tree.all.to_a
      TreeRelationship.delete_all

      trees.each do |tree|
        add_neighbors(tree)
        add_same_species(tree, trees)
        add_long_distance(tree, trees)

        log_relationship_summary(tree)
      end
    end

    private

    def log_relationship_summary(tree)
      counts = fetch_relationship_counts(tree.id)
      tree_name = if tree.respond_to?(:name)
                    tree.name.to_s.strip
                  elsif tree.respond_to?(:[])
                    tree[:name].to_s.strip
                  else
                    ''
                  end
      display_name = tree_name.empty? ? '(unnamed)' : tree_name

      summary = counts
                .sort_by { |kind, _| kind }
                .map { |kind, count| "#{kind}=#{count}" }
                .join(', ')
      summary = 'none' if summary.empty?
      puts "Tree ##{tree.id} #{display_name} - #{summary}"
    end

    def add_neighbors(tree)
      tree.neighbors_within(@radius).each do |neighbor|
        create_pair(tree, neighbor, 'neighbor')
      end
    end

    def add_same_species(tree, all_trees)
      matches = all_trees.select do |other|
        other != tree && tree.treedb_common_name && !tree.treedb_common_name.to_s.strip.empty? &&
          other.treedb_common_name == tree.treedb_common_name
      end
      matches.each do |other|
        create_pair(tree, other, 'same_species')
      end
    end

    def add_long_distance(tree, all_trees)
      candidates = all_trees.reject { |t| t == tree }
      return if candidates.empty?

      max = [candidates.size, 6].min
      rand(1..max).times do
        friend = candidates.sample
        create_pair(tree, friend, 'long_distance')
      end
    end

    def create_pair(tree_a, tree_b, kind)
      [[tree_a, tree_b], [tree_b, tree_a]].each do |x, y|
        rel = TreeRelationship.find_or_create_by!(tree_id: x.id, related_tree_id: y.id, kind: kind)
        rel.update!(tag: TreeRelationship::TAGS.sample)
      end
    end

    def fetch_relationship_counts(tree_id)
      if TreeRelationship.respond_to?(:records)
        Array(TreeRelationship.records)
          .select { |r| fetch_value(r, :tree_id) == tree_id }
          .group_by { |r| fetch_value(r, :kind) }
          .transform_values(&:size)
      elsif TreeRelationship.respond_to?(:where)
        TreeRelationship.where(tree_id: tree_id).group(:kind).count
      else
        {}
      end
    end

    def fetch_value(record, key)
      if record.respond_to?(key)
        record.public_send(key)
      elsif record.respond_to?(:[])
        record[key] || record[key.to_s]
      end
    end
  end
end

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
      end
    end

    private

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
  end
end

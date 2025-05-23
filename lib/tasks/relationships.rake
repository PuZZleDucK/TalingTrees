# frozen_string_literal: true

namespace :db do
  desc 'Add relationships between trees'
  task add_relationships: :environment do
    radius = 20
    trees = Tree.all.to_a

    TreeRelationship.delete_all

    def create_pair(a, b, kind)
      [[a, b], [b, a]].each do |x, y|
        rel = TreeRelationship.find_or_create_by!(tree_id: x.id, related_tree_id: y.id, kind: kind)
        rel.update!(tag: TreeRelationship::TAGS.sample)
      end
    end

    trees.each do |tree|
      # Neighbor relationships within radius
      neighbors = tree.neighbors_within(radius)
      neighbors.each do |neighbor|
        create_pair(tree, neighbor, 'neighbor')
      end

      # Relationships with same species
      species_matches = trees.select do |other|
        other != tree &&
          tree.treedb_common_name && !tree.treedb_common_name.to_s.strip.empty? &&
          other.treedb_common_name == tree.treedb_common_name
      end
      species_matches.each do |other|
        create_pair(tree, other, 'same_species')
      end

      # Long distance friends
      candidates = trees.reject { |t| t == tree }
      next if candidates.empty?

      max = [candidates.size, 6].min
      num = rand(1..max)
      candidates.sample(num).each do |friend|
        create_pair(tree, friend, 'long_distance')
      end
    end
  end
end

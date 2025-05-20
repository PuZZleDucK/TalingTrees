namespace :db do
  desc 'Add relationships between trees'
  task add_relationships: :environment do
    radius = 10
    trees = Tree.all.to_a

    TreeRelationship.delete_all

    trees.each do |tree|
      # Neighbor relationships within radius
      neighbors = tree.neighbors_within(radius)
      neighbors.each do |neighbor|
        TreeRelationship.find_or_create_by!(tree_id: tree.id, related_tree_id: neighbor.id, kind: 'neighbor')
      end

      # Relationships with same species
      species_matches = trees.select do |other|
        other != tree &&
          tree.treedb_common_name.present? &&
          other.treedb_common_name == tree.treedb_common_name
      end
      species_matches.each do |other|
        TreeRelationship.find_or_create_by!(tree_id: tree.id, related_tree_id: other.id, kind: 'same_species')
      end

      # Long distance friends
      candidates = trees.reject { |t| t == tree }
      num = [3, candidates.size].min
      candidates.sample(num).each do |friend|
        TreeRelationship.find_or_create_by!(tree_id: tree.id, related_tree_id: friend.id, kind: 'long_distance')
      end
    end
  end
end

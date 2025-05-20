namespace :db do
  desc 'Add relationships between trees'
  task add_relationships: :environment do
    radius = 20
    trees = Tree.all.to_a

    TreeRelationship.delete_all

    trees.each do |tree|
      # Neighbor relationships within radius
      neighbors = tree.neighbors_within(radius)
      neighbors.each do |neighbor|
        rel = TreeRelationship.find_or_create_by!(tree_id: tree.id, related_tree_id: neighbor.id, kind: 'neighbor')
        rel.update!(tag: TreeRelationship::TAGS.sample)
      end

      # Relationships with same species
      species_matches = trees.select do |other|
        other != tree &&
          tree.treedb_common_name && !tree.treedb_common_name.to_s.strip.empty? &&
          other.treedb_common_name == tree.treedb_common_name
      end
      species_matches.each do |other|
        rel = TreeRelationship.find_or_create_by!(tree_id: tree.id, related_tree_id: other.id, kind: 'same_species')
        rel.update!(tag: TreeRelationship::TAGS.sample)
      end

      # Long distance friends
      candidates = trees.reject { |t| t == tree }
      unless candidates.empty?
        max = [candidates.size, 6].min
        num = rand(1..max)
        candidates.sample(num).each do |friend|
          rel = TreeRelationship.find_or_create_by!(tree_id: tree.id, related_tree_id: friend.id, kind: 'long_distance')
          rel.update!(tag: TreeRelationship::TAGS.sample)
        end
      end
    end
  end
end

class User < ApplicationRecord
  has_many :user_trees, dependent: :destroy
  has_many :trees, through: :user_trees

  def closest_trees(limit = 5)
    return [] unless lat && long

    Tree.all.to_a
        .select { |t| t.treedb_lat && t.treedb_long }
        .sort_by { |t| Tree.haversine_distance(lat, long, t.treedb_lat, t.treedb_long) }
        .first(limit)
  end

  def ensure_initial_trees!(limit = 5)
    return if user_trees.any?

    closest = closest_trees(limit)
    closest = Tree.all.limit(limit) if closest.empty?
    closest.each { |tree| user_trees.create!(tree: tree) }
  end
end

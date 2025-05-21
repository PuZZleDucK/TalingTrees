class User < ApplicationRecord
  has_many :user_trees, dependent: :destroy
  has_many :known_trees, through: :user_trees, source: :tree
  has_many :tree_tags, dependent: :destroy
  has_many :tagged_trees, through: :tree_tags, source: :tree
  has_many :user_tags, dependent: :destroy
  has_many :tagging_trees, through: :user_tags, source: :tree

  def closest_trees(limit = 5)
    return Tree.all.to_a.first(limit) unless lat && long

    Tree.all.to_a
        .select { |t| t.treedb_lat && t.treedb_long }
        .sort_by { |t| Tree.haversine_distance(lat, long, t.treedb_lat, t.treedb_long) }
        .first(limit)
  end

  def tags_from_trees
    if UserTag.respond_to?(:where)
      UserTag.where(user_id: id).pluck(:tag)
    else
      Array(UserTag.records).select { |t| t[:user_id] == id }.map { |t| t[:tag] }
    end
  end

  def tags_for_tree(tree)
    return [] unless tree && respond_to?(:id)

    scope = if UserTag.respond_to?(:where)
              UserTag.where(tree_id: tree.id, user_id: id)
            else
              Array(UserTag.records).select do |t|
                t[:tree_id] == tree.id && t[:user_id] == id
              end
            end
    scope.map { |t| t.respond_to?(:tag) ? t.tag : t[:tag] }
  end

  def chat_tags_prompt
    tags = tags_from_trees.uniq
    return '' if tags.empty?
    "\nOther trees have said this user is: #{tags.join(', ')}."
  end
end

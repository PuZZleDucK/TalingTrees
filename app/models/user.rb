# frozen_string_literal: true

# Application user with associations to trees and tags.
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

  def tag_counts_from_trees
    tags_from_trees.tally
  end

  def tag_details_from_trees
    grouped_records.transform_values do |recs|
      {
        count: recs.length,
        names: extract_tree_names(recs)
      }
    end
  end

  def grouped_records
    records = if UserTag.respond_to?(:where)
                UserTag.includes(:tree).where(user_id: id)
              else
                Array(UserTag.records).select { |t| t[:user_id] == id }
              end
    records.group_by { |rec| rec.respond_to?(:tag) ? rec.tag : rec[:tag] }
  end

  def extract_tree_names(records)
    records.map do |r|
      if r.respond_to?(:tree)
        r.tree.name
      else
        r[:tree_name]
      end
    end.compact
  end

  def tags_for_tree(tree)
    return [] unless tree && respond_to?(:id)

    tree_user_tags(tree).map { |t| tag_value(t) }
  end

  def tree_user_tags(tree)
    if UserTag.respond_to?(:where)
      UserTag.where(tree_id: tree.id, user_id: id)
    else
      Array(UserTag.records).select { |t| t[:tree_id] == tree.id && t[:user_id] == id }
    end
  end

  def tag_value(record)
    record.respond_to?(:tag) ? record.tag : record[:tag]
  end

  def chat_tags_prompt
    details = tag_details_from_trees
    return '' if details.empty?

    parts = details.map do |tag, info|
      names = Array(info[:names]).map(&:to_s).reject(&:empty?)
      if names.any?
        "#{tag} (#{names.join(', ')})"
      else
        tag
      end
    end

    "\nOther trees have said this user is: #{parts.join(', ')}."
  end

  def admin?
    name.to_s.strip.casecmp?('admin')
  end

  private :grouped_records, :extract_tree_names, :tree_user_tags, :tag_value
end

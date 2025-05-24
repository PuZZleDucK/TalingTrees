# frozen_string_literal: true

# Represents a tree and provides helper methods for relationships and
# distance calculations.
class Tree < ApplicationRecord
  EARTH_RADIUS = 6_371_000.0

  has_many :user_trees, dependent: :destroy
  has_many :users, through: :user_trees
  has_many :tree_tags, dependent: :destroy
  has_many :tree_relationships, dependent: :destroy

  def self.haversine_distance(lat1, lon1, lat2, lon2)
    rad_per_deg = Math::PI / 180
    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlon_rad = (lon2 - lon1) * rad_per_deg
    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg

    a = (Math.sin(dlat_rad / 2)**2) +
        (Math.cos(lat1_rad) * Math.cos(lat2_rad) *
        (Math.sin(dlon_rad / 2)**2))
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    EARTH_RADIUS * c
  end

  def neighbors_within(radius)
    return [] unless treedb_lat && treedb_long

    self.class.all.to_a.select do |tree|
      next false if tree == self || tree.treedb_lat.nil? || tree.treedb_long.nil?

      self.class.haversine_distance(treedb_lat, treedb_long,
                                    tree.treedb_lat, tree.treedb_long) <= radius
    end
  end

  def chat_relationship_prompt
    return '' unless respond_to?(:id) && id

    parts = relationship_parts
    return '' if parts.empty?

    "\n#{parts.join(' ')} Feel free to mention them casually by their FULL personal names."
  end

  def relationship_parts
    { 'neighbor' => 'neighbors', 'long_distance' => 'friends' }.filter_map do |kind, label|
      info = relationships_of_kind(kind).filter_map { |rel| format_relationship(rel) }
      "#{label.capitalize} include: #{info.join(', ')}." if info.any?
    end
  end

  def format_relationship(rel)
    related = rel.respond_to?(:related_tree) ? rel.related_tree : rel[:related_tree]
    name = related&.name.to_s.strip
    return if name.empty?

    species = if related.respond_to?(:treedb_common_name)
                related.treedb_common_name.to_s.strip
              else
                related[:treedb_common_name].to_s.strip
              end
    tag = rel.respond_to?(:tag) ? rel.tag.to_s : rel[:tag].to_s

    details = []
    details << "tag: #{tag}" unless tag.nil? || tag.empty?
    details << "species: #{species}" unless species.empty?
    "#{name} (#{details.join(', ')})"
  end

  def relationships_of_kind(kind)
    if respond_to?(:tree_relationships) && tree_relationships.loaded?
      tree_relationships.select { |rel| rel.kind == kind }
    elsif TreeRelationship.respond_to?(:where)
      TreeRelationship.where(tree_id: id, kind: kind)
    else
      Array(TreeRelationship.records).select { |r| r[:tree_id] == id && r[:kind] == kind }
    end
  end

  def neighbor_ids
    relationships_of_kind('neighbor').map do |rel|
      rel.respond_to?(:related_tree_id) ? rel.related_tree_id : rel[:related_tree_id]
    end
  end

  def friend_ids
    relationships_of_kind('long_distance').map do |rel|
      rel.respond_to?(:related_tree_id) ? rel.related_tree_id : rel[:related_tree_id]
    end
  end

  def same_species_ids
    relationships_of_kind('same_species').map do |rel|
      rel.respond_to?(:related_tree_id) ? rel.related_tree_id : rel[:related_tree_id]
    end
  end

  def tags_for_user(user)
    return [] unless user && respond_to?(:id)

    user_tree_tags(user).map { |t| tag_value(t) }
  end

  def user_tree_tags(user)
    if respond_to?(:tree_tags) && tree_tags.loaded?
      tree_tags.select { |t| t.user_id == user.id }
    elsif TreeTag.respond_to?(:where)
      TreeTag.where(tree_id: id, user_id: user.id)
    else
      Array(TreeTag.records).select { |t| t[:tree_id] == id && t[:user_id] == user.id }
    end
  end

  def tag_value(record)
    record.respond_to?(:tag) ? record.tag : record[:tag]
  end

  def tag_counts
    return {} unless respond_to?(:id)

    scope = if respond_to?(:tree_tags) && tree_tags.loaded?
              tree_tags
            elsif TreeTag.respond_to?(:where)
              TreeTag.where(tree_id: id)
            else
              Array(TreeTag.records).select { |t| t[:tree_id] == id }
            end
    scope.each_with_object(Hash.new(0)) do |rec, h|
      tag = rec.respond_to?(:tag) ? rec.tag : rec[:tag]
      h[tag] += 1
    end
  end

  private :relationship_parts, :format_relationship, :user_tree_tags, :tag_value
end

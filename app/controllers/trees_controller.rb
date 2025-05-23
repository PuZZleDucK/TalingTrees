# frozen_string_literal: true

# Provides endpoints for listing and interacting with trees.
class TreesController < ApplicationController
  def index
    @trees = if @current_user&.user_trees&.any?
               @current_user.known_trees
             else
               @current_user ? @current_user.closest_trees : Tree.all
             end

    known_ids = @current_user&.known_trees&.map(&:id) || []

    @tree_data = @trees.map do |tree|
      neighbor_ids = tree.neighbor_ids
      friend_ids = tree.friend_ids
      species_ids = tree.same_species_ids
      {
        id: tree.id,
        name: tree.name,
        treedb_lat: tree.treedb_lat,
        treedb_long: tree.treedb_long,
        neighbor_total: neighbor_ids.length,
        neighbor_known: (neighbor_ids & known_ids).length,
        friend_total: friend_ids.length,
        friend_known: (friend_ids & known_ids).length,
        species_total: species_ids.length,
        species_known: (species_ids & known_ids).length,
        tag_counts: tree.tag_counts,
        user_tags: tree.tags_for_user(@current_user)
      }
    end
  end

  def show
    tree = Tree.find(params[:id])
    known_ids = @current_user&.known_trees&.map(&:id) || []
    neighbor_ids = tree.neighbor_ids
    friend_ids = tree.friend_ids
    species_ids = tree.same_species_ids
    render json: {
      id: tree.id,
      name: tree.name,
      treedb_lat: tree.treedb_lat,
      treedb_long: tree.treedb_long,
      neighbor_total: neighbor_ids.length,
      neighbor_known: (neighbor_ids & known_ids).length,
      friend_total: friend_ids.length,
      friend_known: (friend_ids & known_ids).length,
      species_total: species_ids.length,
      species_known: (species_ids & known_ids).length,
      neighbors: neighbor_ids.map { |nid| { id: nid, name: Tree.find(nid).name } },
      friends: friend_ids.map { |fid| { id: fid, name: Tree.find(fid).name } },
      same_species: species_ids.map { |sid| { id: sid, name: Tree.find(sid).name } },
      tag_counts: tree.tag_counts,
      user_tags: tree.tags_for_user(@current_user)
    }
  end

  def tag
    tree = Tree.find(params[:id])
    tag = params[:tag].to_s
    TreeTag.find_or_create_by!(tree: tree, user: @current_user, tag: tag) if TreeTag::ALLOWED_TAGS.include?(tag)
    render json: {
      tag_counts: tree.tag_counts,
      user_tags: tree.tags_for_user(@current_user)
    }
  end

  def tag_user
    tree = Tree.find(params[:id])
    tag = params[:tag].to_s
    UserTag.find_or_create_by!(tree: tree, user: @current_user, tag: tag) if UserTag::ALLOWED_TAGS.include?(tag)
    render json: {
      tags: @current_user.tags_from_trees,
      tag_details: @current_user.tag_details_from_trees,
      user_tags: @current_user.tags_for_tree(tree)
    }
  end

  def untag
    tree = Tree.find(params[:id])
    tag = params[:tag].to_s
    if TreeTag::ALLOWED_TAGS.include?(tag)
      rec = TreeTag.where(tree: tree, user: @current_user, tag: tag).first
      rec&.destroy
    end
    render json: {
      tag_counts: tree.tag_counts,
      user_tags: tree.tags_for_user(@current_user)
    }
  end
end

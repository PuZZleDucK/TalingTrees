# frozen_string_literal: true

require_relative '../presenters/tree_presenter'
# Provides endpoints for listing and interacting with trees.
class TreesController < ApplicationController
  def index
    scope = select_trees
    scope = scope.includes(:tree_relationships, :tree_tags) if scope.respond_to?(:includes)
    @trees = scope
    known_ids = @current_user&.known_trees&.map(&:id) || []
    @tree_data = @trees.map { |t| TreePresenter.new(t, @current_user).summary_data(known_ids) }
  end

  def show
    tree = Tree.find(params[:id])
    presenter = TreePresenter.new(tree, @current_user)
    render json: presenter.summary_data(presenter.known_ids_for_user).merge(presenter.related_ids_data)
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

  private

  def select_trees
    if @current_user&.user_trees&.any?
      @current_user.known_trees
    elsif @current_user
      @current_user.closest_trees
    else
      Tree.all
    end
  end
end

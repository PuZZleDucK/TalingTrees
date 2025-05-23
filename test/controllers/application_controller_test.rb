# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'

class ApplicationController
  attr_reader :current_user

  def initialize(user)
    @current_user = user
  end

  def head(status) = status

  def update_location(params)
    @current_user.update!(lat: params[:lat], long: params[:long]) if @current_user && params[:lat] && params[:long]
    head :ok
  end

  def know_tree(params)
    if @current_user && (tree = params[:tree])
      @current_user.known_trees ||= []
      @current_user.known_trees << tree unless @current_user.known_trees.include?(tree)
    end
    head :ok
  end
end

class ApplicationControllerTest < Minitest::Test
  def test_update_location_updates_user
    user = User.new
    controller = ApplicationController.new(user)
    controller.update_location(lat: 1.5, long: 2.5)
    assert_equal 1.5, user.lat
    assert_equal 2.5, user.long
  end

  def test_know_tree_adds_tree_to_user
    user = User.new
    user.define_singleton_method(:known_trees) { @known_trees ||= [] }
    tree = Tree.new
    controller = ApplicationController.new(user)
    controller.know_tree(tree: tree)
    assert_includes user.known_trees, tree
  end
end

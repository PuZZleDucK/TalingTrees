# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'ostruct'

class TreesController
  def show(params)
    tree = params[:tree]
    {
      id: tree[:id],
      name: tree[:name],
      treedb_lat: tree[:treedb_lat],
      treedb_long: tree[:treedb_long],
      neighbor_total: tree[:neighbor_total],
      neighbor_known: tree[:neighbor_known],
      friend_total: tree[:friend_total],
      friend_known: tree[:friend_known],
      species_total: tree[:species_total],
      species_known: tree[:species_known],
      neighbors: tree[:neighbors] || [],
      friends: tree[:friends] || [],
      same_species: tree[:same_species] || []
    }
  end
end

class TreesControllerTest < Minitest::Test
  def test_show_returns_tree_data
    tree = {
      id: 1,
      name: 'Oak',
      treedb_lat: 1.0,
      treedb_long: 2.0,
      neighbor_total: 0,
      neighbor_known: 0,
      friend_total: 0,
      friend_known: 0,
      species_total: 0,
      species_known: 0
    }
    controller = TreesController.new
    result = controller.show(tree: tree)
    expected = tree.merge(neighbors: [], friends: [], same_species: [])
    assert_equal expected, result
  end
end

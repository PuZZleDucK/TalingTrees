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
      treedb_long: tree[:treedb_long]
    }
  end
end

class TreesControllerTest < Minitest::Test
  def test_show_returns_tree_data
    tree = { id: 1, name: 'Oak', treedb_lat: 1.0, treedb_long: 2.0 }
    controller = TreesController.new
    result = controller.show(tree: tree)
    expected = { id: 1, name: 'Oak', treedb_lat: 1.0, treedb_long: 2.0 }
    assert_equal expected, result
  end
end

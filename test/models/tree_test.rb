require_relative '../test_helper'
require 'minitest/autorun'

class TreeTest < Minitest::Test
  def test_class_defined
    assert defined?(Tree)
  end

  def test_neighbors_within_returns_close_trees
    Tree.singleton_class.class_eval do
      attr_accessor :records
      def all; records || []; end
    end

    t1 = Tree.new(treedb_lat: 0.0, treedb_long: 0.0)
    t2 = Tree.new(treedb_lat: 0.0, treedb_long: 0.00005) # ~5.5m
    t3 = Tree.new(treedb_lat: 1.0, treedb_long: 1.0)
    Tree.records = [t1, t2, t3]

    neighbors = t1.neighbors_within(10)
    assert_includes neighbors, t2
    refute_includes neighbors, t3
  ensure
    Tree.records = nil
  end
end

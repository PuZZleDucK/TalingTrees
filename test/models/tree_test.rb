# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'

class TreeTest < Minitest::Test
  def test_class_defined
    assert defined?(Tree)
  end

  def test_neighbors_within_returns_close_trees
    Tree.singleton_class.class_eval do
      attr_accessor :records

      def all = records || []
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

  def test_same_species_ids_returns_matching_ids
    TreeRelationship.singleton_class.class_eval do
      attr_accessor :records

      def where(tree_id:, kind:)
        Array(records).select { |r| r[:tree_id] == tree_id && r[:kind] == kind }
      end
    end

    tree = Tree.new
    tree.define_singleton_method(:id) { 1 }
    TreeRelationship.records = [
      { tree_id: 1, related_tree_id: 2, kind: 'same_species' },
      { tree_id: 1, related_tree_id: 3, kind: 'neighbor' }
    ]

    assert_equal [2], tree.same_species_ids
  ensure
    TreeRelationship.records = nil
  end
end

# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'

class TreeTest < Minitest::Test
  def test_class_defined
    assert defined?(Tree)
  end

  def test_neighbors_within_returns_empty_when_coordinates_missing
    tree = Tree.new
    assert_equal [], tree.neighbors_within(10)
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
    prev_where = TreeRelationship.method(:where) if TreeRelationship.respond_to?(:where)
    TreeRelationship.singleton_class.class_eval do
      attr_accessor :records

      def where(tree_id:, kind: nil)
        Array(records).select { |r| r[:tree_id] == tree_id && (kind.nil? || r[:kind] == kind) }
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
    if prev_where
      TreeRelationship.define_singleton_method(:where, prev_where)
    else
      TreeRelationship.singleton_class.remove_method(:where)
    end
  end

  def test_neighbor_ids_returns_only_neighbor_ids
    prev_where = TreeRelationship.method(:where) if TreeRelationship.respond_to?(:where)
    TreeRelationship.singleton_class.class_eval do
      attr_accessor :records

      def where(tree_id:, kind: nil)
        Array(records).select { |r| r[:tree_id] == tree_id && (kind.nil? || r[:kind] == kind) }
      end
    end

    tree = Tree.new(id: 1)
    TreeRelationship.records = [
      { tree_id: 1, related_tree_id: 2, kind: 'neighbor' },
      { tree_id: 1, related_tree_id: 3, kind: 'long_distance' }
    ]

    assert_equal [2], tree.neighbor_ids
  ensure
    TreeRelationship.records = nil
    if prev_where
      TreeRelationship.define_singleton_method(:where, prev_where)
    else
      TreeRelationship.singleton_class.remove_method(:where)
    end
  end

  def test_friend_ids_returns_only_friend_ids
    prev_where = TreeRelationship.method(:where) if TreeRelationship.respond_to?(:where)
    TreeRelationship.singleton_class.class_eval do
      attr_accessor :records

      def where(tree_id:, kind: nil)
        Array(records).select { |r| r[:tree_id] == tree_id && (kind.nil? || r[:kind] == kind) }
      end
    end

    tree = Tree.new(id: 1)
    TreeRelationship.records = [
      { tree_id: 1, related_tree_id: 2, kind: 'neighbor' },
      { tree_id: 1, related_tree_id: 3, kind: 'long_distance' }
    ]

    assert_equal [3], tree.friend_ids
  ensure
    TreeRelationship.records = nil
    if prev_where
      TreeRelationship.define_singleton_method(:where, prev_where)
    else
      TreeRelationship.singleton_class.remove_method(:where)
    end
  end

  def test_tags_for_user_filters_by_user
    TreeTag.singleton_class.class_eval { attr_accessor :records }
    TreeTag.records = [
      { tree_id: 1, user_id: 1, tag: 'good' },
      { tree_id: 1, user_id: 2, tag: 'funny' }
    ]
    tree = Tree.new(id: 1)
    user = User.new(id: 2)

    assert_equal ['funny'], tree.tags_for_user(user)
  ensure
    TreeTag.records = nil
  end
end

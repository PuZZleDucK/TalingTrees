# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../app/controllers/trees_controller'

Tree.singleton_class.class_eval do
  attr_accessor :records unless method_defined?(:records)

  unless method_defined?(:find)
    send(:define_method, :find) do |id|
      Array(records).find { |t| t.id == id }
    end
  end

  unless method_defined?(:all)
    send(:define_method, :all) { Array(records) }
  end
end

class TreesControllerTest < Minitest::Test
  def test_show_returns_tree_data
    t1 = Tree.new(id: 1, name: 'Oak', treedb_lat: 1.0, treedb_long: 2.0)
    t2 = Tree.new(id: 2, name: 'Pine')
    t3 = Tree.new(id: 3, name: 'Birch')

    t1.define_singleton_method(:neighbor_ids) { [2] }
    t1.define_singleton_method(:friend_ids) { [3] }
    t1.define_singleton_method(:same_species_ids) { [] }
    t1.define_singleton_method(:tag_counts) { { 'good' => 1 } }
    t1.define_singleton_method(:tags_for_user) { |_user| ['good'] }

    Tree.singleton_class.class_eval do
      attr_accessor :records

      def find(id)
        Array(records).find { |t| t.id == id }
      end
    end

    Tree.records = [t1, t2, t3]

    user = User.new
    user.define_singleton_method(:known_trees) { [t2] }

    controller = TreesController.new
    controller.instance_variable_set(:@current_user, user)
    controller.params = { id: 1 }
    controller.show

    expected = {
      id: 1,
      name: 'Oak',
      treedb_lat: 1.0,
      treedb_long: 2.0,
      neighbor_total: 1,
      neighbor_known: 1,
      friend_total: 1,
      friend_known: 0,
      species_total: 0,
      species_known: 0,
      tag_counts: { 'good' => 1 },
      user_tags: ['good'],
      neighbors: [{ id: 2, name: 'Pine' }],
      friends: [{ id: 3, name: 'Birch' }],
      same_species: []
    }

    assert_equal expected, controller.rendered
  ensure
    Tree.records = nil
  end

  def test_tag_creates_record
    tree = Tree.new(id: 1)
    tree.define_singleton_method(:tag_counts) { { 'good' => 1 } }
    tree.define_singleton_method(:tags_for_user) { |_user| ['good'] }
    Tree.singleton_class.class_eval do
      attr_accessor :records

      def find(id)
        Array(records).find { |t| t.id == id }
      end
    end
    Tree.records = [tree]
    TreeTag.singleton_class.class_eval do
      attr_accessor :records

      def find_or_create_by!(attrs)
        self.records ||= []
        normalized = {
          tree_id: attrs[:tree]&.id || attrs[:tree_id],
          user_id: attrs[:user]&.id || attrs[:user_id],
          tag: attrs[:tag]
        }
        unless records.any? { |r| r == normalized }
          records << normalized
        end
        normalized
      end
    end
    TreeTag.records = []

    controller = TreesController.new
    controller.instance_variable_set(:@current_user, User.new(id: 2))
    controller.params = { id: 1, tag: 'good' }
    controller.tag

    expected = { tree_id: 1, user_id: 2, tag: 'good' }
    assert_includes TreeTag.records, expected
  ensure
    Tree.records = nil
    TreeTag.records = nil
  end

  def test_tag_user_applies_allowed_tag
    tree = Tree.new(id: 10)
    Tree.records = [tree]

    user = User.new(id: 42)
    user_tags = %w[friendly]
    tag_details = { 'friendly' => ['Tree 10'] }
    per_tree_tags = %w[friendly]
    user.define_singleton_method(:tags_from_trees) { user_tags }
    user.define_singleton_method(:tag_details_from_trees) { tag_details }
    user.define_singleton_method(:tags_for_tree) { |_t| per_tree_tags }

    UserTag.singleton_class.class_eval do
      attr_accessor :records

      def find_or_create_by!(attrs)
        self.records ||= []
        normalized = {
          tree_id: attrs[:tree]&.id || attrs[:tree_id],
          user_id: attrs[:user]&.id || attrs[:user_id],
          tag: attrs[:tag]
        }
        unless records.any? { |r| r == normalized }
          records << normalized
        end
        normalized
      end
    end
    UserTag.records = []

    controller = TreesController.new
    controller.instance_variable_set(:@current_user, user)
    controller.params = { id: 10, tag: 'friendly' }
    controller.tag_user

    expected_record = { tree_id: 10, user_id: 42, tag: 'friendly' }
    assert_includes UserTag.records, expected_record
    assert_equal({ tags: user_tags, tag_details: tag_details, user_tags: per_tree_tags }, controller.rendered)
  ensure
    UserTag.records = nil if UserTag.respond_to?(:records=)
    Tree.records = nil
  end

  def test_untag_removes_tag_when_allowed
    tree = Tree.new(id: 15)
    tree.define_singleton_method(:tag_counts) { { 'good' => 1 } }
    tree.define_singleton_method(:tags_for_user) { |_user| [] }
    Tree.records = [tree]

    record = Object.new
    record.define_singleton_method(:destroy) { @destroyed = true }
    record.define_singleton_method(:destroyed?) { !!@destroyed }

    relation = Struct.new(:record) do
      include Enumerable

      def each
        yield record if record
      end

      def first
        record
      end
    end

    TreeTag.singleton_class.class_eval do
      attr_accessor :test_relation, :test_where_args

      def where(attrs)
        self.test_where_args = attrs
        return test_relation if test_relation

        self.records ||= []
        tree_id = attrs[:tree]&.id || attrs[:tree_id]
        user_id = attrs[:user]&.id || attrs[:user_id]
        tag = attrs[:tag]

        records.select do |rec|
          matches_tree = tree_id.nil? || rec[:tree_id] == tree_id
          matches_user = user_id.nil? || rec[:user_id] == user_id
          matches_tag = tag.nil? || rec[:tag] == tag
          matches_tree && matches_user && matches_tag
        end
      end
    end

    TreeTag.test_relation = relation.new(record)
    TreeTag.test_where_args = nil

    user = User.new
    controller = TreesController.new
    controller.instance_variable_set(:@current_user, user)
    controller.params = { id: 15, tag: 'good' }
    controller.untag

    assert TreeTag.test_where_args, 'expected TreeTag.where to be invoked'
    assert record.destroyed?, 'expected the matching record to be destroyed'
    assert_equal({ tag_counts: { 'good' => 1 }, user_tags: [] }, controller.rendered)
  ensure
    TreeTag.test_relation = nil if TreeTag.respond_to?(:test_relation=)
    TreeTag.test_where_args = nil if TreeTag.respond_to?(:test_where_args=)
    Tree.records = nil
  end

  def test_index_populates_tree_data_for_known_trees
    tree = Tree.new(id: 1, name: 'Oak', treedb_lat: 1.5, treedb_long: 3.2)
    tree.define_singleton_method(:neighbor_ids) { [2] }
    tree.define_singleton_method(:friend_ids) { [3] }
    tree.define_singleton_method(:same_species_ids) { [] }
    tree.define_singleton_method(:tag_counts) { { 'friendly' => 2 } }
    tree.define_singleton_method(:tags_for_user) { |_user| ['friendly'] }
    Tree.records = [tree]

    user = User.new
    user.define_singleton_method(:user_trees) { [Object.new] }
    user.define_singleton_method(:known_trees) { [tree] }

    controller = TreesController.new
    controller.instance_variable_set(:@current_user, user)
    controller.index

    expected = {
      id: 1,
      name: 'Oak',
      treedb_lat: 1.5,
      treedb_long: 3.2,
      neighbor_total: 1,
      neighbor_known: 0,
      friend_total: 1,
      friend_known: 0,
      species_total: 0,
      species_known: 0,
      tag_counts: { 'friendly' => 2 },
      user_tags: ['friendly']
    }

    assert_equal [expected], controller.instance_variable_get(:@tree_data)
  ensure
    Tree.records = nil
  end

  def test_select_trees_without_known_returns_closest
    user = User.new
    user.define_singleton_method(:user_trees) { [] }
    closest = [Tree.new(id: 55)]
    user.define_singleton_method(:closest_trees) { closest }
    user.define_singleton_method(:known_trees) { [] }

    controller = TreesController.new
    controller.instance_variable_set(:@current_user, user)

    assert_equal closest, controller.send(:select_trees)
  end

  def test_tag_actions_are_public
    c = TreesController.new
    assert c.respond_to?(:tag)
    assert c.respond_to?(:tag_user)
    assert c.respond_to?(:untag)
  end
end

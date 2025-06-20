# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../app/controllers/trees_controller'

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
        rec = records.find { |r| r == attrs }
        unless rec
          rec = attrs.dup
          records << rec
        end
        rec
      end
    end
    TreeTag.records = []

    controller = TreesController.new
    controller.instance_variable_set(:@current_user, User.new(id: 2))
    controller.params = { id: 1, tag: 'good' }
    controller.tag

    expected = { tree: tree, user: controller.instance_variable_get(:@current_user), tag: 'good' }
    assert_includes TreeTag.records, expected
  ensure
    Tree.records = nil
    TreeTag.records = nil
  end

  def test_tag_actions_are_public
    c = TreesController.new
    assert c.respond_to?(:tag)
    assert c.respond_to?(:tag_user)
    assert c.respond_to?(:untag)
  end
end

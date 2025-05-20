require_relative '../test_helper'
require 'minitest/autorun'

class UserTest < Minitest::Test
  def test_class_defined
    assert defined?(User)
  end

  def test_ensure_initial_trees_creates_nearest_relations
    user = User.new
    user.define_singleton_method(:lat) { 0.0 }
    user.define_singleton_method(:long) { 0.0 }

    assoc = Class.new do
      attr_reader :created
      def initialize; @created = []; end
      def any?; @created.any?; end
      def create!(attrs); @created << attrs; end
    end.new
    user.define_singleton_method(:user_trees) { assoc }

    Tree.singleton_class.class_eval do
      attr_accessor :records
      def all; records || []; end
      def limit(n); all.first(n); end
    end

    t1 = Tree.new(treedb_lat: 0.0, treedb_long: 0.0)
    t2 = Tree.new(treedb_lat: 0.0, treedb_long: 0.0001)
    t3 = Tree.new(treedb_lat: 1.0, treedb_long: 1.0)
    Tree.records = [t1, t2, t3]

    user.ensure_initial_trees!(2)

    assert_equal 2, assoc.created.size
    assert_equal [t1, t2], assoc.created.map { |r| r[:tree] }
  ensure
    Tree.records = nil
  end
end

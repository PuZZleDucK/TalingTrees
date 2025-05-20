require_relative '../test_helper'
require 'minitest/autorun'

class UserClosestTreesTest < Minitest::Test
  def setup
    Tree.singleton_class.class_eval do
      attr_accessor :records
      def all; records || []; end
    end
  end

  def teardown
    Tree.records = nil
  end

  def test_returns_five_closest
    user = User.new(lat: 0.0, long: 0.0)
    close_trees = (1..6).map do |i|
      Tree.new(treedb_lat: 0.0, treedb_long: 0.00001 * i, name: "t#{i}")
    end
    Tree.records = close_trees
    result = user.closest_trees
    assert_equal 5, result.size
    assert_equal %w[t1 t2 t3 t4 t5], result.map(&:name)
  end
end

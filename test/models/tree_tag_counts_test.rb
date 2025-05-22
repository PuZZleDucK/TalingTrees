require_relative '../test_helper'
require 'minitest/autorun'

class TreeTagCountsTest < Minitest::Test
  def test_tag_counts_returns_counts
    TreeTag.singleton_class.class_eval { attr_accessor :records }
    TreeTag.records = [
      { tree_id: 1, user_id: 1, tag: 'good' },
      { tree_id: 1, user_id: 2, tag: 'good' },
      { tree_id: 1, user_id: 3, tag: 'funny' },
      { tree_id: 2, user_id: 1, tag: 'good' }
    ]
    tree = Tree.new(id: 1)
    counts = tree.tag_counts
    assert_equal({ 'good' => 2, 'funny' => 1 }, counts)
  ensure
    TreeTag.records = nil
  end
end

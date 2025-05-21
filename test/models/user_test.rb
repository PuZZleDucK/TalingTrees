require_relative '../test_helper'
require 'minitest/autorun'

class UserTest < Minitest::Test
  def test_class_defined
    assert defined?(User)
  end

  def test_tags_for_tree_returns_user_specific_tags
    UserTag.singleton_class.class_eval { attr_accessor :records }
    UserTag.records = [
      { tree_id: 1, user_id: 2, tag: 'friendly' },
      { tree_id: 2, user_id: 2, tag: 'helpful' }
    ]
    user = User.new(id: 2)
    tree1 = OpenStruct.new(id: 1)
    assert_equal ['friendly'], user.tags_for_tree(tree1)
  ensure
    UserTag.records = nil
  end
end

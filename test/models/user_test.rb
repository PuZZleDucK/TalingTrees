# frozen_string_literal: true

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

  def test_tag_counts_from_trees_returns_totals
    UserTag.singleton_class.class_eval { attr_accessor :records }
    UserTag.records = [
      { tree_id: 1, user_id: 2, tag: 'friendly' },
      { tree_id: 2, user_id: 2, tag: 'friendly' },
      { tree_id: 3, user_id: 2, tag: 'helpful' }
    ]
    user = User.new(id: 2)
    counts = user.tag_counts_from_trees
    assert_equal({ 'friendly' => 2, 'helpful' => 1 }, counts)
  ensure
    UserTag.records = nil
  end

  def test_tag_details_from_trees_returns_counts_and_names
    UserTag.singleton_class.class_eval { attr_accessor :records }
    UserTag.records = [
      { tree_id: 1, user_id: 2, tag: 'friendly', tree_name: 'Oak' },
      { tree_id: 2, user_id: 2, tag: 'friendly', tree_name: 'Pine' },
      { tree_id: 3, user_id: 2, tag: 'helpful', tree_name: 'Birch' }
    ]
    user = User.new(id: 2)
    details = user.tag_details_from_trees
    expected = {
      'friendly' => { count: 2, names: %w[Oak Pine] },
      'helpful' => { count: 1, names: ['Birch'] }
    }
    assert_equal expected, details
  ensure
    UserTag.records = nil
  end

  def test_chat_tags_prompt_includes_tree_names
    UserTag.singleton_class.class_eval { attr_accessor :records }
    UserTag.records = [
      { tree_id: 1, user_id: 2, tag: 'friendly', tree_name: 'Oak' },
      { tree_id: 2, user_id: 2, tag: 'helpful', tree_name: 'Pine' }
    ]
    user = User.new(id: 2)
    prompt = user.chat_tags_prompt
    assert_includes prompt, 'friendly (Oak)'
    assert_includes prompt, 'helpful (Pine)'
  ensure
    UserTag.records = nil
  end
end

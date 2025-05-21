require_relative '../test_helper'
require 'minitest/autorun'

class TreeChatRelationshipPromptTest < Minitest::Test
  def setup
    TreeRelationship.singleton_class.class_eval do
      attr_accessor :records
      def where(tree_id:, kind:)
        Array(records).select { |r| r.tree_id == tree_id && kind.include?(r.kind) }
      end
    end
  end

  def teardown
    TreeRelationship.records = nil
  end

  def test_prompt_includes_extra_info
    tree = Tree.new(id: 1)
    neighbor = Tree.new(name: 'Oakly', treedb_common_name: 'Oak')
    friend = Tree.new(name: 'Piny', treedb_common_name: 'Pine')

    rel1 = TreeRelationship.new(tree_id: 1, related_tree: neighbor, kind: 'neighbor', tag: 'nemesis')
    rel2 = TreeRelationship.new(tree_id: 1, related_tree: friend, kind: 'long_distance', tag: 'best-friend')

    TreeRelationship.records = [rel1, rel2]

    prompt = tree.chat_relationship_prompt

    assert_includes prompt, 'Neighbors include:'
    assert_includes prompt, 'Friends include:'
    assert_includes prompt, 'Oakly'
    assert_includes prompt, 'species: Oak'
    assert_includes prompt, 'tag: nemesis'
    assert_includes prompt, 'tag: best-friend'
  end
end

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../lib/import_trees'

class ImportTreesTest < Minitest::Test
  def test_remaining_without_count_returns_default
    task = Tasks::ImportTrees.new
    assert_equal Tasks::ImportTrees::DEFAULT_LIMIT, task.send(:remaining, 0)
  end

  def test_remaining_with_count_limits_properly
    task = Tasks::ImportTrees.new(count: 10)
    assert_equal 10, task.send(:remaining, 0)
    assert_equal 5, task.send(:remaining, 5)
    assert_equal 0, task.send(:remaining, 15)
  end

  def test_stop_returns_true_when_count_reached
    task = Tasks::ImportTrees.new(count: 2)
    assert task.send(:stop?, 2)
    refute task.send(:stop?, 1)
  end

  def test_import_record_sets_fields_and_saves
    saved = false
    tree = Tree.new
    tree.define_singleton_method(:new_record?) { true }
    tree.define_singleton_method(:changed?) { true }
    tree.define_singleton_method(:save!) { saved = true }
    Tree.singleton_class.class_eval do
      attr_accessor :obj
      def find_or_initialize_by(treedb_com_id:)
        self.obj
      end
    end
    Tree.obj = tree

    fields = {
      'com_id' => '1',
      'common_name' => 'Oak',
      'genus' => 'Quercus',
      'latitude' => '1',
      'longitude' => '2'
    }
    Tasks::ImportTrees.new.send(:import_record, fields)

    assert_equal 'Oak', tree.treedb_common_name
    assert_equal 'Quercus', tree.treedb_genus
    assert_equal '1', tree.treedb_lat
    assert_equal '2', tree.treedb_long
    assert saved
  ensure
    Tree.obj = nil
  end
end

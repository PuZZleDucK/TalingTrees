require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'

class AddRelationshipsTaskTest < Minitest::Test
  class << self
    def setup_tree_class
      Tree.class_eval do
        class << self
          attr_accessor :instances
          def all; instances || []; end
          def find_each
            (instances || []).each { |t| yield t }
          end
        end
      end
    end
  end

  def setup
    self.class.setup_tree_class

    @t1 = Tree.new(treedb_lat: 0.0, treedb_long: 0.0, treedb_common_name: 'A')
    @t1.define_singleton_method(:id) { 1 }
    @t2 = Tree.new(treedb_lat: 0.0, treedb_long: 0.00005, treedb_common_name: 'A')
    @t2.define_singleton_method(:id) { 2 }
    @t3 = Tree.new(treedb_lat: 1.0, treedb_long: 1.0, treedb_common_name: 'B')
    @t3.define_singleton_method(:id) { 3 }
    @t4 = Tree.new(treedb_lat: 2.0, treedb_long: 2.0, treedb_common_name: 'C')
    @t4.define_singleton_method(:id) { 4 }
    Tree.instances = [@t1, @t2, @t3, @t4]

    TreeRelationship.singleton_class.class_eval do
      attr_accessor :records
      def find_or_create_by!(attrs)
        self.records ||= []
        rec = self.records.find { |r| r[:tree_id] == attrs[:tree_id] && r[:related_tree_id] == attrs[:related_tree_id] && r[:kind] == attrs[:kind] }
        unless rec
          rec = attrs.dup
          self.records << rec
        end
        Struct.new(:record) do
          define_method(:update!) { |h| record.merge!(h) }
        end.new(rec)
      end
      def delete_all
        self.records = []
      end
    end
    TreeRelationship.records = []

    srand 0

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/relationships.rake', __dir__)
  end

  def teardown
    Tree.instances = nil
    TreeRelationship.records = []
  end

  def test_creates_neighbor_and_species_relationships
    Rake.application['db:add_relationships'].invoke

    assert TreeRelationship.records.any? { |r| r[:tree_id] == 1 && r[:related_tree_id] == 2 && r[:kind] == 'neighbor' }
    assert TreeRelationship.records.any? { |r| r[:tree_id] == 1 && r[:related_tree_id] == 2 && r[:kind] == 'same_species' }

    long_distance_count = TreeRelationship.records.count { |r| r[:tree_id] == 1 && r[:kind] == 'long_distance' }
    assert_operator long_distance_count, :>=, 1

    TreeRelationship.records.each do |rec|
      assert_includes TreeRelationship::TAGS, rec[:tag]
    end
  end

  def test_relationships_are_mutual
    Rake.application['db:add_relationships'].invoke

    assert TreeRelationship.records.any? { |r| r[:tree_id] == 2 && r[:related_tree_id] == 1 && r[:kind] == 'neighbor' }
    assert TreeRelationship.records.any? { |r| r[:tree_id] == 2 && r[:related_tree_id] == 1 && r[:kind] == 'same_species' }
  end
end

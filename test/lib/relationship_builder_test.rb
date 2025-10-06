# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../lib/relationship_builder'

class RelationshipBuilderTest < Minitest::Test
  RelationshipRecord = Struct.new(:tree_id, :related_tree_id, :kind, :tag) do
    def update!(attrs)
      attrs.each { |key, value| public_send("#{key}=", value) }
    end
  end

  class FakeTree
    attr_reader :id, :treedb_common_name
    attr_writer :neighbors

    def initialize(id:, common_name:)
      @id = id
      @treedb_common_name = common_name
      @neighbors = []
    end

    def neighbors_within(_radius)
      @neighbors
    end
  end

  def setup
    Tree.singleton_class.class_eval do
      attr_accessor :records

      def all
        records || []
      end
    end

    TreeRelationship.singleton_class.class_eval do
      attr_accessor :records, :delete_called

      def delete_all
        self.records = []
        self.delete_called = true
      end

      def where(conditions)
        selected = Array(records).select { |rec| rec.tree_id == conditions[:tree_id] }
        Struct.new(:rows) do
          def group(key)
            grouped = rows.group_by { |r| r.public_send(key) }
            Struct.new(:grouped) do
              def count
                grouped.transform_values(&:size)
              end
            end.new(grouped)
          end
        end.new(selected)
      end

      def find_or_create_by!(tree_id:, related_tree_id:, kind:)
        self.records ||= []
        record = records.find do |rec|
          rec.tree_id == tree_id && rec.related_tree_id == related_tree_id && rec.kind == kind
        end
        unless record
          record = RelationshipBuilderTest::RelationshipRecord.new(tree_id, related_tree_id, kind, nil)
          records << record
        end
        record
      end
    end

    TreeRelationship.delete_called = false
    TreeRelationship.records = []
  end

  def teardown
    Tree.records = nil
    TreeRelationship.records = nil
    TreeRelationship.delete_called = nil
  end

  def test_run_creates_neighbor_species_and_long_distance_relationships
    tree1 = FakeTree.new(id: 1, common_name: 'Oak')
    tree2 = FakeTree.new(id: 2, common_name: 'Oak')
    tree1.neighbors = [tree2]
    tree2.neighbors = [tree1]
    Tree.records = [tree1, tree2]

    builder = Tasks::RelationshipBuilder.new(radius: 10)
    builder.stub(:rand, 1) { builder.run }

    records = TreeRelationship.records

    assert TreeRelationship.delete_called, 'expected relationships to be wiped before rebuild'
    assert_equal 6, records.size
    kinds = records.map(&:kind)
    assert_equal 2, kinds.count('neighbor')
    assert_equal 2, kinds.count('same_species')
    assert_equal 2, kinds.count('long_distance')
    assert records.all? { |rec| TreeRelationship::TAGS.include?(rec.tag) && !rec.tag.nil? }
  end

  def test_run_skips_long_distance_when_no_candidates
    solo = FakeTree.new(id: 1, common_name: 'Maple')
    solo.neighbors = []
    Tree.records = [solo]

    builder = Tasks::RelationshipBuilder.new(radius: 5)
    builder.stub(:rand, 1) { builder.run }

    assert TreeRelationship.delete_called, 'expected existing relationships to be cleared'
    assert_empty TreeRelationship.records
  end
end

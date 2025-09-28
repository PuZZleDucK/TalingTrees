# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../lib/tree_namer'
require_relative '../../app/models/point_of_interest'

class TreeFactsTest < Minitest::Test
  def setup
    @tree = Struct.new(:treedb_lat, :treedb_long).new(0.5, 0.5)

    def @tree.attributes
      {
        'id' => 1,
        'name' => nil,
        'treedb_lat' => 0.5,
        'treedb_long' => 0.5
      }
    end

    def @tree.neighbors_within(_radius)
      []
    end

    if defined?(PointOfInterest)
      PointOfInterest.singleton_class.class_eval do
        attr_accessor :records unless method_defined?(:records)

        def all
          records || []
        end
      end
      PointOfInterest.records = []
    end

    @facts = Tasks::TreeFacts.new(@tree)
  end

  def teardown
    PointOfInterest.records = nil if defined?(PointOfInterest) && PointOfInterest.respond_to?(:records=)
  end

  def test_landmarks_with_distances_supports_hash_records
    PointOfInterest.records = [
      { site_name: 'Hashy Site', centroid_lat: '0.5001', centroid_long: '0.5001' }
    ]

    distances = @facts.send(:landmarks_with_distances)

    assert_equal 1, distances.size
    assert_equal 'Hashy Site', distances.first[:name]
    assert distances.first[:distance] > 0
  end

  def test_landmarks_with_distances_handles_errors_gracefully
    PointOfInterest.stub(:all, proc { raise StandardError, 'boom' }) do
      assert_equal [], @facts.send(:landmarks_with_distances)
    end
  end

  def test_facts_omits_landmark_section_when_no_valid_points
    invalid_name = Struct.new(:site_name, :centroid_lat, :centroid_long).new('   ', 0.5, 0.5)
    bad_coordinates = { site_name: 'Broken', centroid_lat: 'invalid', centroid_long: '0.5001' }
    PointOfInterest.records = [invalid_name, bad_coordinates]

    summary = @facts.facts

    refute_includes summary, 'closest_landmark'
    refute_includes summary, 'landmarks_within_50m'
  end

  def test_landmarks_with_distances_returns_empty_without_coordinates
    tree = Struct.new(:treedb_lat, :treedb_long).new(nil, nil)

    def tree.attributes
      { 'id' => 2, 'name' => nil, 'treedb_lat' => nil, 'treedb_long' => nil }
    end

    facts = Tasks::TreeFacts.new(tree)
    assert_equal [], facts.send(:landmarks_with_distances)
  end
end

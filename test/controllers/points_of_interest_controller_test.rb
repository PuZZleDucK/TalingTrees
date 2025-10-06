# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../app/controllers/points_of_interest_controller'
require_relative '../../app/models/point_of_interest'

class PointsOfInterestControllerTest < Minitest::Test
  def setup
    PointOfInterest.singleton_class.class_eval do
      attr_accessor :records unless respond_to?(:records)

      def all
        Array(records)
      end
    end

    PointOfInterest.records = []
  end

  def teardown
    PointOfInterest.records = nil if PointOfInterest.respond_to?(:records=)
  end

  def test_index_renders_points_with_coordinates
    poi = PointOfInterest.new(
      id: 1,
      site_name: 'Test POI',
      vhr_number: 'H123',
      hermes_number: '999',
      herit_obj: 'Y',
      category: 'heritage',
      centroid_lat: -37.8,
      centroid_long: 145.0,
      boundary: 'POLYGON((145  -37.8, 145.1 -37.8, 145.1 -37.7, 145 -37.7, 145 -37.8))'
    )
    PointOfInterest.records = [poi]

    controller = PointsOfInterestController.new
    controller.index

    expected = [{
      id: 1,
      site_name: 'Test POI',
      vhr_number: 'H123',
      hermes_number: '999',
      herit_obj: 'Y',
      category: 'heritage',
      category_label: 'Heritage Site',
      category_style: {
        'color' => '#b45309',
        'fill_color' => '#f59e0b',
        'radius' => 6
      },
      centroid_lat: -37.8,
      centroid_long: 145.0,
      polygons: [
        [
          [-37.8, 145.0],
          [-37.8, 145.1],
          [-37.7, 145.1],
          [-37.7, 145.0],
          [-37.8, 145.0]
        ]
      ]
    }]

    assert_equal expected, controller.rendered
  end

  def test_index_skips_points_without_coordinates
    poi = PointOfInterest.new(site_name: 'No coords')
    PointOfInterest.records = [poi]

    controller = PointsOfInterestController.new
    controller.index

    assert_equal [], controller.rendered
  end

  def test_index_includes_category_for_ptv_points
    poi = PointOfInterest.new(
      id: 2,
      site_name: 'Southern Cross Station',
      centroid_lat: -37.8183,
      centroid_long: 144.9526,
      category: 'ptv_train'
    )
    PointOfInterest.records = [poi]

    controller = PointsOfInterestController.new
    controller.index

    expected = [{
      id: 2,
      site_name: 'Southern Cross Station',
      vhr_number: nil,
      hermes_number: nil,
      herit_obj: nil,
      category: 'ptv_train',
      category_label: 'Train Station',
      category_style: {
        'color' => '#1d4ed8',
        'fill_color' => '#60a5fa',
        'radius' => 5
      },
      centroid_lat: -37.8183,
      centroid_long: 144.9526,
      polygons: []
    }]

    assert_equal expected, controller.rendered
  end

  def test_safe_number_handles_invalid_values
    controller = PointsOfInterestController.new
    result = controller.send(:safe_number, { 'centroid_lat' => 'not-a-number' }, :centroid_lat)
    assert_nil result
  end
end

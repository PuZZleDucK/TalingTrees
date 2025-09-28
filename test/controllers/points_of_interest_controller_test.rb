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
      centroid_lat: -37.8,
      centroid_long: 145.0
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
      centroid_lat: -37.8,
      centroid_long: 145.0
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
end

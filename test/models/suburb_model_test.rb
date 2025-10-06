# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../app/models/suburb'
require 'rgeo'

class SuburbModelTest < Minitest::Test
  def setup
    @factory = RGeo::Geographic.spherical_factory(srid: 4326)
    points = [
      @factory.point(144.0, -38.0),
      @factory.point(145.0, -38.0),
      @factory.point(145.0, -37.0),
      @factory.point(144.0, -37.0),
      @factory.point(144.0, -38.0)
    ]
    ring = @factory.linear_ring(points)
    @polygon = @factory.polygon(ring)

    polygon = @polygon
    @suburb = Suburb.new
    @suburb.define_singleton_method(:boundary) { polygon }
  end

  def test_contains_point_returns_true_when_inside_polygon
    assert @suburb.contains_point?(-37.5, 144.5)
  end

  def test_contains_point_returns_false_when_outside_polygon
    refute @suburb.contains_point?(-36.0, 150.0)
  end

  def test_polygons_returns_lat_long_pairs
    polygons = @suburb.polygons
    assert_equal 1, polygons.length
    first_polygon = polygons.first
    assert_includes first_polygon, [-38.0, 144.0]
    assert_includes first_polygon, [-37.0, 145.0]
  end

  def test_polygons_handles_multi_polygon
    factory = @factory
    polygon = @polygon
    multi = factory.multi_polygon([polygon, polygon])
    suburb = Suburb.new
    suburb.define_singleton_method(:boundary) { multi }

    polygons = suburb.polygons
    assert_equal 2, polygons.length
  end

  def test_contains_point_handles_invalid_wkt
    invalid = Suburb.new
    invalid.define_singleton_method(:boundary) { 'INVALID' }
    refute invalid.contains_point?(0, 0)
    assert_equal [], invalid.polygons
  end

  def test_find_containing_uses_records_fallback
    Suburb.singleton_class.class_eval do
      attr_accessor :records unless respond_to?(:records)
    end

    inside = Suburb.new
    inside.define_singleton_method(:contains_point?) { |lat, lon| lat == 1.0 && lon == 2.0 }
    outside = Suburb.new
    outside.define_singleton_method(:contains_point?) { |_lat, _lon| false }

    Suburb.records = [outside, inside]

    assert_nil Suburb.find_containing(nil, 2.0)
    assert_equal inside, Suburb.find_containing(1.0, 2.0)
  ensure
    Suburb.records = nil if Suburb.respond_to?(:records=)
  end

end

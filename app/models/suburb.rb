# frozen_string_literal: true

require 'rgeo'

# Represents a suburb boundary polygon.
class Suburb < ApplicationRecord
  # Returns an array of polygons representing the suburb boundary.
  # Each polygon is an array of [lat, lon] coordinate pairs.
  def polygons
    unless defined?(::RGeo)
      $LOADED_FEATURES.delete_if { |p| p.end_with?('/rgeo.rb') }
      require 'rgeo'
    end
    geom = boundary
    unless geom.respond_to?(:geometry_type)
      factory = ::RGeo::Geographic.spherical_factory(srid: 4326)
      begin
        geom = ::RGeo::WKRep::WKTParser.new(factory, support_ewkt: true).parse(boundary.to_s)
      rescue ::RGeo::Error::ParseError
        return []
      end
    end

    if geom.geometry_type == ::RGeo::Feature::MultiPolygon
      geom.map { |poly| ring_coords(poly.exterior_ring) }
    elsif geom.geometry_type == ::RGeo::Feature::Polygon
      [ring_coords(geom.exterior_ring)]
    else
      []
    end
  end

  # Returns true if the given lat/long pair falls within the suburb boundary.
  def contains_point?(lat, lon)
    return false if lat.nil? || lon.nil?

    unless defined?(::RGeo)
      $LOADED_FEATURES.delete_if { |p| p.end_with?('/rgeo.rb') }
      require 'rgeo'
    end

    geom = boundary
    factory = if geom.respond_to?(:factory)
                geom.factory
              else
                ::RGeo::Geographic.spherical_factory(srid: 4326)
              end
    unless geom.respond_to?(:geometry_type)
      begin
        geom = ::RGeo::WKRep::WKTParser.new(factory, support_ewkt: true).parse(boundary.to_s)
      rescue ::RGeo::Error::ParseError
        return false
      end
    end

    point = factory.point(lon, lat)
    geom.contains?(point)
  end

  # Finds the suburb that contains the given coordinates.
  def self.find_containing(lat, lon)
    return nil if lat.nil? || lon.nil?

    scope = if respond_to?(:where)
              all
            elsif respond_to?(:records)
              Array(records)
            else
              []
            end
    scope = scope.to_a if scope.respond_to?(:to_a)
    scope.find { |s| s.contains_point?(lat, lon) }
  end

  private

  def ring_coords(ring)
    ring.points.map { |p| [p.y, p.x] }
  end
end

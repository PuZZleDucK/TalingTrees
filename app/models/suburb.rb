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

  private

  def ring_coords(ring)
    ring.points.map { |p| [p.y, p.x] }
  end
end

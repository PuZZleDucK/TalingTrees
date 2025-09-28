# frozen_string_literal: true

# Exposes heritage points of interest for map display.
class PointsOfInterestController < ApplicationController
  def index
    points = load_points

    render json: points.map { |poi| point_payload(poi) }
  end

  private

  def load_points
    if PointOfInterest.respond_to?(:all)
      collection = PointOfInterest.all
      collection = collection.to_a if collection.respond_to?(:to_a)
      collection
    else
      Array(PointOfInterest.records)
    end.select { |poi| valid_coordinates?(poi) }
  end

  def valid_coordinates?(poi)
    lat = safe_number(poi, :centroid_lat)
    lng = safe_number(poi, :centroid_long)
    !lat.nil? && !lng.nil?
  end

  def safe_number(obj, attr)
    value = if obj.respond_to?(attr)
              obj.public_send(attr)
            else
              obj[attr]
            end
    return if value.nil?

    Float(value)
  rescue ArgumentError, TypeError
    nil
  end

  def point_payload(poi)
    {
      id: attribute_for(poi, :id),
      site_name: attribute_for(poi, :site_name),
      vhr_number: attribute_for(poi, :vhr_number),
      hermes_number: attribute_for(poi, :hermes_number),
      herit_obj: attribute_for(poi, :herit_obj),
      centroid_lat: attribute_for(poi, :centroid_lat).to_f,
      centroid_long: attribute_for(poi, :centroid_long).to_f,
      polygons: polygons_for(poi)
    }
  end

  def attribute_for(obj, attr)
    if obj.respond_to?(attr)
      obj.public_send(attr)
    else
      obj[attr]
    end
  end

  def polygons_for(poi)
    boundary = attribute_for(poi, :boundary)
    return [] if boundary.nil? || boundary.empty?

    geometry = parse_wkt(boundary)
    return [] unless geometry

    case geometry
    when RGeo::Feature::MultiPolygon
      geometry.map { |poly| polygon_to_coordinates(poly) }.compact
    when RGeo::Feature::Polygon
      coords = polygon_to_coordinates(geometry)
      coords ? [coords] : []
    else
      []
    end
  rescue StandardError
    []
  end

  def polygon_to_coordinates(polygon)
    exterior = polygon.exterior_ring
    return nil unless exterior

    exterior.points.map { |point| [point.y, point.x] }
  end

  def parse_wkt(text)
    return nil if text.blank?

    wkt_parser.parse(text)
  rescue RGeo::Error::ParseError
    nil
  end

  def wkt_factory
    @wkt_factory ||= RGeo::Geographic.spherical_factory(srid: 4326)
  end

  def wkt_parser
    @wkt_parser ||= RGeo::WKRep::WKTParser.new(wkt_factory, support_ewkt: true)
  end
end

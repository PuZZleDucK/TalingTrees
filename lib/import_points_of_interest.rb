# frozen_string_literal: true

module Tasks
  # Imports heritage register polygons as points of interest records.
  class ImportPointsOfInterest
    DEFAULT_PATH = File.expand_path('../data/heritage/HERITAGE_REGISTER.shp', __dir__)

    def initialize(path: DEFAULT_PATH)
      @path = path.nil? || path.to_s.empty? ? DEFAULT_PATH : path
    end

    def run
      require 'rgeo'
      require 'rgeo/geos'
      require 'rgeo/shapefile'
      require 'time'
      raise "Shapefile not found at #{@path}" unless File.exist?(@path)

      PointOfInterest.delete_all

      factory = RGeo::Geos.factory(
        srid: 4326,
        buffer_resolution: 2,
        lenient_multi_polygon_assertions: true
      )

      RGeo::Shapefile::Reader.open(
        @path,
        factory: factory,
        lenient_multi_polygon_assertions: true,
        validate_geometries: false
      ) do |file|
        loop do
          record = begin
            file.next
          rescue RGeo::Error::InvalidGeometry => e
            warn "Skipping malformed record: #{e.message}"
            next
          rescue StandardError => e
            warn "Stopping shapefile read due to #{e.class}: #{e.message}"
            break
          end

          break unless record

          begin
            attrs = record.attributes
            site_name = attrs['SITE_NAME']&.strip
            next if site_name.nil? || site_name.empty?

            geometry = record.geometry
            next unless geometry

            centroid = geometry.respond_to?(:centroid) ? geometry.centroid : nil
            boundary_value = boundary_for(geometry)

            hermes = blank_to_nil(attrs['HERMES_NUM'])
            PointOfInterest.create!(
              site_name: site_name,
              vhr_number: attrs['VHR_NUM']&.strip,
              vhi_number: blank_to_nil(attrs['VHI_NUM']),
              herit_obj: attrs['HERIT_OBJ']&.strip,
              hermes_number: hermes&.to_s,
              ufi: attrs['UFI']&.to_i,
              external_id: attrs['ID']&.to_i,
              ufi_created_at: parse_time(attrs['UFI_CR']),
              centroid_lat: centroid&.y,
              centroid_long: centroid&.x,
              boundary: boundary_value
            )
          rescue RGeo::Error::InvalidGeometry => e
            warn "Skipping point of interest \"#{site_name}\": #{e.message}"
            next
          rescue StandardError => e
            warn "Skipping point of interest \"#{site_name}\" due to #{e.class}: #{e.message}"
            next
          end
        end
      end
    end

    private

    def parse_time(raw)
      return if raw.nil? || raw.to_s.strip.empty?

      Time.parse(raw.to_s)
    rescue ArgumentError
      nil
    end

    def blank_to_nil(value)
      value = value.to_s.strip
      value.empty? ? nil : value
    end

    def boundary_for(geometry)
      if PointOfInterest.columns_hash['boundary'].type == :text
        geometry.respond_to?(:as_text) ? geometry.as_text : geometry.to_s
      else
        geometry
      end
    end
  end
end

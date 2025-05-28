# frozen_string_literal: true

module Tasks
  # Imports suburb polygon data from a shapefile.
  class ImportSuburbs
    DEFAULT_FILE = File.expand_path('../data/suburbs/GDA2020/vic_localities.shp', __dir__)

    def initialize(file: DEFAULT_FILE)
      @file = file || DEFAULT_FILE
    end

    def run
      require 'rgeo/shapefile'

      Suburb.delete_all
      begin
        RGeo::Shapefile::Reader.open(@file) do |file|
          file.each do |record|
            attrs = record.attributes
            name = attrs['NAME'] || attrs['LOCALITY'] || attrs['suburb_name'] || attrs['LOC_NAME']
            polygon = record.geometry
            next unless name && polygon

            Suburb.create!(name: name, boundary: polygon)
          end
        end
      rescue RGeo::Error::RGeoError => e
        message = 'ImportSuburbs requires GEOS to parse polygons. Install libgeos and reinstall rgeo.'
        raise RGeo::Error::RGeoError, "#{message}\n#{e.message}"
      end
    end
  end
end

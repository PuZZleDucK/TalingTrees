# frozen_string_literal: true

module Tasks
  # Imports suburb boundary data from a shapefile.
  class ImportSuburbs
    DEFAULT_PATH = File.expand_path('../data/suburbs/GDA2020/vic_localities.shp', __dir__)

    def initialize(path: DEFAULT_PATH)
      @path = path.nil? || path.to_s.empty? ? DEFAULT_PATH : path
    end

    def run
      require 'rgeo/shapefile'
      raise "Shapefile not found at #{@path}" unless File.exist?(@path)

      Suburb.delete_all

      RGeo::Shapefile::Reader.open(@path) do |file|
        file.each do |record|
          attrs = record.attributes
          name = attrs['NAME'] || attrs['LOC_NAME'] || attrs['LOCALITY'] || attrs['suburb_name']
          polygon = record.geometry

          if Suburb.columns_hash['boundary'].type == :text
            Suburb.create!(name: name, boundary: polygon.as_text)
          else
            Suburb.create!(name: name, boundary: polygon)
          end
        end
      end
    end
  end
end

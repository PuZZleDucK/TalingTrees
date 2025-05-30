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

      puts "Starting suburb import from #{@file}"
      Suburb.delete_all
      begin
        RGeo::Shapefile::Reader.open(@file) do |file|
          file.each do |record|
            attrs = record.attributes
            name = attrs['NAME'] || attrs['LOCALITY'] || attrs['suburb_name'] || attrs['LOC_NAME']
            polygon = record.geometry
            next unless name && polygon

            count = tree_count_for_polygon(polygon)
            puts "Found #{count} trees in #{name}" if count.positive?
            Suburb.create!(name: name, boundary: polygon, tree_count: count)
          end
        end
        puts "Suburb count: #{Suburb.count}"
        puts 'Delete started'
        Suburb.where(tree_count: 0).delete_all
        puts 'Delete done'
        puts "Suburb count: #{Suburb.count}"
      rescue RGeo::Error::RGeoError => e
        message = 'ImportSuburbs requires GEOS to parse polygons. Install libgeos and reinstall rgeo.'
        raise RGeo::Error::RGeoError, "#{message}\n#{e.message}"
      end
    end

    private

    def tree_count_for_polygon(polygon)
      factory = polygon.factory
      trees = if Tree.respond_to?(:where)
                Tree.where.not(treedb_lat: nil, treedb_long: nil)
              else
                Array(Tree.records).select { |t| t[:treedb_lat] && t[:treedb_long] }
              end
      trees = trees.to_a if trees.respond_to?(:to_a)
      trees.count do |tree|
        lat = tree.respond_to?(:treedb_lat) ? tree.treedb_lat : tree[:treedb_lat]
        lon = tree.respond_to?(:treedb_long) ? tree.treedb_long : tree[:treedb_long]
        point = factory.point(lon, lat)
        polygon.contains?(point)
      end
    end
  end
end

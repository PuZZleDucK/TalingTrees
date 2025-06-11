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

          count = tree_count_for_polygon(polygon)

          next if count.zero?

          if Suburb.columns_hash['boundary'].type == :text
            Suburb.create!(name: name, boundary: polygon.as_text, tree_count: count)
          else
            Suburb.create!(name: name, boundary: polygon, tree_count: count)
          end
        end
      end
    end

    private

    def tree_count_for_polygon(polygon)
      factory = polygon.factory
      scope = if Tree.respond_to?(:where)
                Tree.where.not(treedb_lat: nil, treedb_long: nil)
              else
                Array(Tree.records).select { |t| t[:treedb_lat] && t[:treedb_long] }
              end
      scope = scope.to_a if scope.respond_to?(:to_a)
      scope.count do |tree|
        lat = tree.respond_to?(:treedb_lat) ? tree.treedb_lat : tree[:treedb_lat]
        lon = tree.respond_to?(:treedb_long) ? tree.treedb_long : tree[:treedb_long]
        point = factory.point(lon, lat)
        polygon.contains?(point)
      end
    end
  end
end

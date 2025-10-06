# frozen_string_literal: true

module Tasks
  # Provides fast proximity checks between coordinates and existing trees.
  class NearTreeFilter
    BUCKET_SIZE = 0.001 # ~111m latitude; sufficient for 100m proximity searches.
    RADIUS_METERS = 100.0

    def initialize
      @index = Hash.new { |hash, key| hash[key] = [] }
      build_index
    end

    def near?(lat, lon)
      return false if lat.nil? || lon.nil? || @index.empty?

      bucket_lat, bucket_lon = bucket_for(lat, lon)
      neighbors = []
      -1.upto(1) do |di|
        -1.upto(1) do |dj|
          neighbors.concat(@index[[bucket_lat + di, bucket_lon + dj]])
        end
      end
      return false if neighbors.empty?

      neighbors.any? do |tree_lat, tree_lon|
        Tree.haversine_distance(lat.to_f, lon.to_f, tree_lat, tree_lon) <= RADIUS_METERS
      end
    rescue StandardError
      false
    end

    private

    def build_index
      scope = if Tree.respond_to?(:where)
                Tree.where.not(treedb_lat: nil, treedb_long: nil).pluck(:treedb_lat, :treedb_long)
              elsif Tree.respond_to?(:records)
                Array(Tree.records).map do |record|
                  [value_for(record, :treedb_lat), value_for(record, :treedb_long)]
                end
              else
                []
              end
      scope.each do |lat, lon|
        next if lat.nil? || lon.nil?

        bucket = bucket_for(lat.to_f, lon.to_f)
        @index[bucket] << [lat.to_f, lon.to_f]
      end
    rescue StandardError
      @index.clear
    end

    def value_for(record, attr)
      if record.respond_to?(attr)
        record.public_send(attr)
      elsif record.respond_to?(:[])
        record[attr] || record[attr.to_s]
      end
    end

    def bucket_for(lat, lon)
      [(lat.to_f / BUCKET_SIZE).floor, (lon.to_f / BUCKET_SIZE).floor]
    end
  end
end

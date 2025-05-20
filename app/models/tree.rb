class Tree < ApplicationRecord
  EARTH_RADIUS = 6_371_000.0

  def self.haversine_distance(lat1, lon1, lat2, lon2)
    rad_per_deg = Math::PI / 180
    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlon_rad = (lon2 - lon1) * rad_per_deg
    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg

    a = Math.sin(dlat_rad / 2)**2 +
        Math.cos(lat1_rad) * Math.cos(lat2_rad) *
        Math.sin(dlon_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    EARTH_RADIUS * c
  end

  def neighbors_within(radius)
    return [] unless treedb_lat && treedb_long

    self.class.all.to_a.select do |tree|
      next false if tree == self || tree.treedb_lat.nil? || tree.treedb_long.nil?
      self.class.haversine_distance(treedb_lat, treedb_long,
                                    tree.treedb_lat, tree.treedb_long) <= radius
    end
  end
end

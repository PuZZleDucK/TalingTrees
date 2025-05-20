class TreesController < ApplicationController
  def index
    counts = TreeRelationship.group(:tree_id, :kind).count
    @trees = Tree.all.map do |t|
      {
        id: t.id,
        name: t.name,
        treedb_lat: t.treedb_lat,
        treedb_long: t.treedb_long,
        species_count: counts[[t.id, 'same_species']] || 0,
        friend_count: counts[[t.id, 'long_distance']] || 0
      }
    end
  end
end

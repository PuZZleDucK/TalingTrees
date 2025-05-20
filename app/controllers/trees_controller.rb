class TreesController < ApplicationController
  def index
    if @current_user&.user_trees&.any?
      @trees = @current_user.known_trees
    else
      @trees = @current_user ? @current_user.closest_trees : Tree.all
    end

    known_ids = @current_user&.known_trees&.map { |t| t.id } || []

    @tree_data = @trees.map do |tree|
      neighbor_ids = tree.neighbor_ids
      friend_ids = tree.friend_ids
      {
        id: tree.id,
        name: tree.name,
        treedb_lat: tree.treedb_lat,
        treedb_long: tree.treedb_long,
        neighbor_total: neighbor_ids.length,
        neighbor_known: (neighbor_ids & known_ids).length,
        friend_total: friend_ids.length,
        friend_known: (friend_ids & known_ids).length
      }
    end
  end

  def show
    tree = Tree.find(params[:id])
    known_ids = @current_user&.known_trees&.map { |t| t.id } || []
    neighbor_ids = tree.neighbor_ids
    friend_ids = tree.friend_ids
    render json: {
      id: tree.id,
      name: tree.name,
      treedb_lat: tree.treedb_lat,
      treedb_long: tree.treedb_long,
      neighbor_total: neighbor_ids.length,
      neighbor_known: (neighbor_ids & known_ids).length,
      friend_total: friend_ids.length,
      friend_known: (friend_ids & known_ids).length
    }
  end
end

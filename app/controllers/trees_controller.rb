class TreesController < ApplicationController
  def index
    if @current_user&.user_trees&.any?
      @trees = @current_user.known_trees
    else
      @trees = @current_user ? @current_user.closest_trees : Tree.all
    end
  end
end

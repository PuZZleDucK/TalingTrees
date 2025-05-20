class TreesController < ApplicationController
  def index
    if @current_user
      @current_user.ensure_initial_trees!
      @trees = @current_user.trees
    else
      @trees = Tree.all
    end
  end
end

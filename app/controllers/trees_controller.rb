class TreesController < ApplicationController
  def index
    @trees = Tree.all
  end
end

class ApplicationController < ActionController::Base
  before_action :set_current_user

  def select_user
    session[:user_id] = params[:user_id]
    redirect_back fallback_location: root_path
  end

  def update_location
    if @current_user && params[:lat] && params[:long]
      @current_user.update!(lat: params[:lat], long: params[:long])
    end
    head :ok
  end

  def know_tree
    if @current_user && params[:id]
      tree = Tree.find_by(id: params[:id])
      UserTree.find_or_create_by!(user: @current_user, tree: tree) if tree
    end
    head :ok
  end

  private

  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
    @current_user ||= User.first
  end
end

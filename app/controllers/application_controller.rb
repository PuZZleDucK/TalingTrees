class ApplicationController < ActionController::Base
  before_action :set_current_user

  def select_user
    session[:user_id] = params[:user_id]
    redirect_back fallback_location: root_path
  end

  private

  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
    @current_user ||= User.first
  end
end

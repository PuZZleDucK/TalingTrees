# frozen_string_literal: true

# Base controller providing common helpers and callbacks for the
# application's controllers.
class ApplicationController < ActionController::Base
  include Ahoy::Controller if defined?(Ahoy::Controller)

  before_action :set_current_user
  helper_method :current_user
  after_action :track_page_view if respond_to?(:after_action)

  def select_user
    session[:user_id] = params[:user_id]
    redirect_back fallback_location: root_path
  end

  def update_location
    @current_user.update!(lat: params[:lat], long: params[:long]) if @current_user && params[:lat] && params[:long]
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

  def track_page_view
    return unless request.get?
    return unless request.format.html?

    tracker = defined?(ahoy) ? ahoy : nil
    return unless tracker

    tracker.track 'Page view',
                  path: request.fullpath,
                  controller: controller_name,
                  action: action_name,
                  user_id: @current_user&.id
  rescue StandardError => e
    Rails.logger.warn("[Ahoy] Failed to track page view: #{e.message}")
  end

  def set_current_user
    current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) || User.find_by(name: 'Alice') || User.first
  end

  def require_admin
    return if current_user&.admin?

    redirect_to root_path, alert: 'Not authorized'
  end
end

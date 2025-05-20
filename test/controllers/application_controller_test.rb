require_relative '../test_helper'
require 'minitest/autorun'

class ApplicationController
  attr_reader :current_user

  def initialize(user)
    @current_user = user
  end

  def head(status); status; end

  def update_location(params)
    if @current_user && params[:lat] && params[:long]
      @current_user.update!(lat: params[:lat], long: params[:long])
    end
    head :ok
  end
end

class ApplicationControllerTest < Minitest::Test
  def test_update_location_updates_user
    user = User.new
    controller = ApplicationController.new(user)
    controller.update_location(lat: 1.5, long: 2.5)
    assert_equal 1.5, user.lat
    assert_equal 2.5, user.long
  end
end

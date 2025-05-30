# frozen_string_literal: true

# Provides suburb boundary data for the map.
class SuburbsController < ApplicationController
  def index
    data = Suburb.all.map { |s| { name: s.name, polygons: s.polygons } }
    render json: data
  end
end

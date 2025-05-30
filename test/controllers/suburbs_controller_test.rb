# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../app/controllers/suburbs_controller'

class SuburbsControllerTest < Minitest::Test
  def setup
    require 'rgeo'
    Suburb.singleton_class.class_eval do
      attr_accessor :records

      def all = records
    end
  end

  def teardown
    Suburb.records = nil
  end

  def test_index_returns_suburb_polygons
    Suburb.records = [
      Suburb.new(name: 'Alpha', boundary: 'POLYGON((0 0,1 0,1 1,0 1,0 0))'),
      Suburb.new(name: 'Beta', boundary: 'POLYGON((2 2,3 2,3 3,2 3,2 2))')
    ]

    controller = SuburbsController.new
    controller.index

    expected = [
      {
        name: 'Alpha',
        polygons: [[
          [0.0, 0.0],
          [0.0, 1.0],
          [1.0, 1.0],
          [1.0, 0.0],
          [0.0, 0.0]
        ]]
      },
      {
        name: 'Beta',
        polygons: [[
          [2.0, 2.0],
          [2.0, 3.0],
          [3.0, 3.0],
          [3.0, 2.0],
          [2.0, 2.0]
        ]]
      }
    ]
    assert_equal expected, controller.rendered
  end
end

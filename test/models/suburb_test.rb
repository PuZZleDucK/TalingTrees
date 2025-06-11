# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'rgeo'

class SuburbTest < Minitest::Test
  def test_polygons_parses_wkt
    s = Suburb.new(boundary: 'POLYGON((0 0,1 0,1 1,0 1,0 0))')
    expected = [[
      [0.0, 0.0],
      [0.0, 1.0],
      [1.0, 1.0],
      [1.0, 0.0],
      [0.0, 0.0]
    ]]
    assert_equal expected, s.polygons
  end
end

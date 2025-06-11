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

  def test_contains_point
    s = Suburb.new(boundary: 'POLYGON((0 0,1 0,1 1,0 1,0 0))')
    assert s.contains_point?(0.5, 0.5)
    refute s.contains_point?(2.0, 2.0)
  end

  def test_find_containing_returns_matching_suburb
    s = Suburb.new(boundary: 'POLYGON((0 0,1 0,1 1,0 1,0 0))')
    Suburb.singleton_class.attr_accessor :records unless Suburb.respond_to?(:records)
    Suburb.records = [s]
    assert_equal s, Suburb.find_containing(0.5, 0.5)
  ensure
    Suburb.records = nil
  end

  def test_find_containing_returns_nil_when_no_match
    s = Suburb.new(boundary: 'POLYGON((0 0,1 0,1 1,0 1,0 0))')
    Suburb.singleton_class.attr_accessor :records unless Suburb.respond_to?(:records)
    Suburb.records = [s]
    assert_nil Suburb.find_containing(2.0, 2.0)
  ensure
    Suburb.records = nil
  end
end

# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../lib/import_suburbs'
require 'ostruct'

module RGeo
  module Shapefile
    class Reader; end
  end
end unless defined?(RGeo::Shapefile::Reader)

class ImportSuburbsTest < Minitest::Test
  class FakeFactory
    def point(lon, lat)
      Struct.new(:lon, :lat).new(lon, lat)
    end
  end

  class FakePolygon
    attr_reader :factory

    def initialize(included_points: [])
      @factory = FakeFactory.new
      @included_points = included_points
    end

    def contains?(point)
      @included_points.any? { |coords| coords[:lat] == point.lat && coords[:lon] == point.lon }
    end

    def as_text
      'POLYGON((0 0,1 0,1 1,0 1,0 0))'
    end
  end

  class FakeRecord
    attr_reader :attributes, :geometry

    def initialize(attrs, geometry)
      @attributes = attrs
      @geometry = geometry
    end
  end

  def setup
    Tree.singleton_class.class_eval do
      attr_accessor :records unless respond_to?(:records)
    end
    Tree.records = []

    Suburb.singleton_class.class_eval do
      attr_accessor :created_records, :columns_type unless respond_to?(:created_records)

      def delete_all
        self.created_records = []
      end

      def columns_hash
        type = columns_type || :text
        { 'boundary' => OpenStruct.new(type: type) }
      end

      def create!(attrs)
        self.created_records ||= []
        self.created_records << attrs
      end
    end

    Suburb.created_records = []
    Suburb.columns_type = :text
  end

  def teardown
    Tree.records = nil
    Suburb.created_records = nil
    Suburb.columns_type = nil
  end

  def test_initialize_with_blank_path_uses_default
    importer = Tasks::ImportSuburbs.new(path: '')
    assert_equal Tasks::ImportSuburbs::DEFAULT_PATH, importer.instance_variable_get(:@path)
  end

  def test_run_raises_when_file_missing
    importer = Tasks::ImportSuburbs.new(path: 'missing.shp')
    File.stub(:exist?, false) do
      importer.stub(:require, nil) do
        error = assert_raises(RuntimeError) { importer.run }
        assert_match(/Shapefile not found/, error.message)
      end
    end
  end

  def test_run_creates_suburb_records_with_text_boundary
    polygon = FakePolygon.new(included_points: [{ lat: 1.0, lon: 2.0 }])
    skip_polygon = FakePolygon.new(included_points: [])
    record = FakeRecord.new({ 'NAME' => 'Alpha' }, polygon)
    skipped = FakeRecord.new({ 'NAME' => 'Skip' }, skip_polygon)
    Tree.records = [
      { treedb_lat: 1.0, treedb_long: 2.0 },
      { treedb_lat: 5.0, treedb_long: 6.0 }
    ]

    stub_reader_with([record, skipped]) do
      File.stub(:exist?, true) do
        importer = Tasks::ImportSuburbs.new(path: 'dummy.shp')
        importer.stub(:require, nil) { importer.run }
      end
    end

    created = Suburb.created_records
    assert_equal 1, created.size
    entry = created.first
    assert_equal 'Alpha', entry[:name]
    assert_equal polygon.as_text, entry[:boundary]
    assert_equal 1, entry[:tree_count]
  end

  def test_tree_count_for_polygon_uses_active_record_scope
    polygon = FakePolygon.new(included_points: [{ lat: 7.0, lon: 8.0 }])
    tree = Struct.new(:treedb_lat, :treedb_long).new(7.0, 8.0)
    relation = Class.new do
      def initialize(records)
        @records = records
      end

      def not(*)
        @records
      end

      def to_a
        @records
      end
    end.new([tree])

    Tree.singleton_class.class_eval do
      define_method(:where) { relation }
    end

    count = Tasks::ImportSuburbs.new.send(:tree_count_for_polygon, polygon)
    assert_equal 1, count
  ensure
    Tree.singleton_class.class_eval do
      remove_method(:where) if method_defined?(:where)
    end
  end

  def test_run_uses_geometry_object_when_boundary_column_not_text
    polygon = FakePolygon.new(included_points: [{ lat: 3.0, lon: 4.0 }])
    record = FakeRecord.new({ 'LOCALITY' => 'Beta' }, polygon)
    Tree.records = [
      { treedb_lat: 3.0, treedb_long: 4.0 }
    ]
    Suburb.columns_type = :geometry

    stub_reader_with([record]) do
      File.stub(:exist?, true) do
        importer = Tasks::ImportSuburbs.new(path: 'dummy.shp')
        importer.stub(:require, nil) { importer.run }
      end
    end

    entry = Suburb.created_records.first
    assert_same polygon, entry[:boundary]
    assert_equal 'Beta', entry[:name]
  end

  private

  def stub_reader_with(records)
    reader = Struct.new(:records) do
      def each
        records.each { |r| yield r }
      end
    end.new(records)

    replacement = proc do |_path, &blk|
      blk.call(reader)
    end

    RGeo::Shapefile::Reader.stub(:open, replacement) do
      yield
    end
  end
end

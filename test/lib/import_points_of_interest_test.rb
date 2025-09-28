# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../lib/import_points_of_interest'
require_relative '../../app/models/point_of_interest'
require 'ostruct'

module RGeo
  module Shapefile
    class Reader; end
  end
end unless defined?(RGeo::Shapefile::Reader)

class ImportPointsOfInterestTest < Minitest::Test
  FakeCentroid = Struct.new(:x, :y)

  class FakeGeometry
    def initialize(text:, centroid:)
      @text = text
      @centroid = centroid
    end

    def centroid
      @centroid
    end

    def as_text
      @text
    end
  end

  class FakeRecord
    attr_reader :attributes, :geometry

    def initialize(attributes, geometry)
      @attributes = attributes
      @geometry = geometry
    end
  end

  def setup
    PointOfInterest.singleton_class.class_eval do
      attr_accessor :created_records unless respond_to?(:created_records)

      def delete_all
        self.created_records = []
      end

      def columns_hash
        type = @boundary_type || :text
        { 'boundary' => OpenStruct.new(type: type) }
      end

      def boundary_type=(type)
        @boundary_type = type
      end

      def create!(attrs)
        self.created_records ||= []
        created_records << attrs
      end
    end

    PointOfInterest.created_records = []
    PointOfInterest.boundary_type = :text
  end

  def teardown
    PointOfInterest.created_records = nil if PointOfInterest.respond_to?(:created_records=)
    PointOfInterest.boundary_type = :text if PointOfInterest.respond_to?(:boundary_type=)
  end

  def test_run_raises_when_missing_file
    importer = Tasks::ImportPointsOfInterest.new(path: 'missing.shp')
    File.stub(:exist?, false) do
      importer.stub(:require, nil) do
        error = assert_raises(RuntimeError) { importer.run }
        assert_match(/Shapefile not found/, error.message)
      end
    end
  end

  def test_run_creates_records_with_parsed_attributes
    geometry = FakeGeometry.new(text: 'MULTIPOLYGON(...)', centroid: FakeCentroid.new(145.0, -37.8))
    attrs = {
      'SITE_NAME' => ' Test Site ',
      'VHR_NUM' => 'H12345',
      'VHI_NUM' => '',
      'HERIT_OBJ' => 'Y',
      'HERMES_NUM' => '9988',
      'UFI' => '1450001',
      'ID' => '1200',
      'UFI_CR' => '2020-05-01T00:00:00Z'
    }
    record = FakeRecord.new(attrs, geometry)

    stub_reader_with([record]) do
      File.stub(:exist?, true) do
        importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp')
        importer.stub(:require, nil) { importer.run }
      end
    end

    created = PointOfInterest.created_records
    assert_equal 1, created.size
    poi = created.first
    assert_equal 'Test Site', poi[:site_name]
    assert_equal 'H12345', poi[:vhr_number]
    assert_equal 'Y', poi[:herit_obj]
    assert_equal '9988', poi[:hermes_number]
    assert_equal 1_450_001, poi[:ufi]
    assert_equal 1_200, poi[:external_id]
    assert_in_delta(-37.8, poi[:centroid_lat])
    assert_in_delta(145.0, poi[:centroid_long])
    assert_equal 'MULTIPOLYGON(...)', poi[:boundary]
  end

  def test_run_skips_blank_site_name
    geometry = FakeGeometry.new(text: 'MULTIPOLYGON(...)', centroid: FakeCentroid.new(0, 0))
    blank_record = FakeRecord.new({ 'SITE_NAME' => '   ' }, geometry)

    stub_reader_with([blank_record]) do
      File.stub(:exist?, true) do
        importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp')
        importer.stub(:require, nil) { importer.run }
      end
    end

    assert_empty PointOfInterest.created_records
  end

  private

  def stub_reader_with(records)
    reader = Class.new do
      def initialize(records)
        @records = records
        @index = 0
      end

      def each(&block)
        @records.each(&block)
      end

      def next
        return nil if @index >= @records.length

        value = @records[@index]
        @index += 1
        value
      end

      def close; end
    end

    RGeo::Shapefile::Reader.stub(:open, proc { |*_args, &blk| blk.call(reader.new(records)) }) do
      yield
    end
  end
end

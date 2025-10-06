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

module RGeo
  module Error
    class InvalidGeometry < StandardError; end
  end
end unless defined?(RGeo::Error::InvalidGeometry)

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

      def where(conditions)
        Struct.new(:records_owner, :conditions) do
          def delete_all
            existing = Array(records_owner.created_records)
            records_owner.created_records = existing.reject do |record|
              conditions.all? do |key, expected|
                value = if record.respond_to?(key)
                          record.public_send(key)
                        else
                          record[key] || record[key.to_s]
                        end
                value == expected
              end
            end
          end
        end.new(self, conditions)
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
    @near_filter = Class.new do
      attr_reader :calls

      def initialize(results: nil)
        @results = Array(results || true)
        @calls = []
      end

      def near?(lat, lon)
        @calls << [lat, lon]
        value = if @results.length > 1
                  @results.shift
                else
                  @results.first
                end
        !!value
      end
    end
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
        importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp', tree_filter: @near_filter.new)
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
    assert_equal 'heritage', poi[:category]
  end

  def test_run_skips_blank_site_name
    geometry = FakeGeometry.new(text: 'MULTIPOLYGON(...)', centroid: FakeCentroid.new(0, 0))
    blank_record = FakeRecord.new({ 'SITE_NAME' => '   ' }, geometry)

    stub_reader_with([blank_record]) do
      File.stub(:exist?, true) do
        importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp', tree_filter: @near_filter.new)
        importer.stub(:require, nil) { importer.run }
      end
    end

    assert_empty PointOfInterest.created_records
  end

  def test_run_sets_nil_for_invalid_temporal_and_blank_values
    geometry = FakeGeometry.new(text: 'MULTIPOLYGON(...)', centroid: FakeCentroid.new(0, 0))
    attrs = {
      'SITE_NAME' => ' Sample Heritage ',
      'VHR_NUM' => nil,
      'VHI_NUM' => '  ',
      'HERIT_OBJ' => 'N',
      'HERMES_NUM' => '  ',
      'UFI' => '',
      'ID' => '42',
      'UFI_CR' => 'invalid timestamp'
    }
    record = FakeRecord.new(attrs, geometry)

    stub_reader_with([record]) do
      File.stub(:exist?, true) do
        importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp', tree_filter: @near_filter.new)
        importer.stub(:require, nil) { importer.run }
      end
    end

    poi = PointOfInterest.created_records.first
    assert_nil poi[:hermes_number]
    assert_nil poi[:vhi_number]
    assert_equal 0, poi[:ufi]
    assert_nil poi[:ufi_created_at]
  end

  def test_run_returns_geometry_object_when_boundary_column_not_text
    geometry = FakeGeometry.new(text: 'IGNORED', centroid: FakeCentroid.new(0, 0))
    attrs = { 'SITE_NAME' => 'Boundary Keeper' }
    PointOfInterest.boundary_type = :geometry
    record = FakeRecord.new(attrs, geometry)

    stub_reader_with([record]) do
      File.stub(:exist?, true) do
        importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp', tree_filter: @near_filter.new)
        importer.stub(:require, nil) { importer.run }
      end
    end

    boundary = PointOfInterest.created_records.first[:boundary]
    assert_same geometry, boundary
  ensure
    PointOfInterest.boundary_type = :text
  end

  def test_run_continues_when_reader_returns_invalid_geometry
    geometry = FakeGeometry.new(text: 'MULTIPOLYGON(...)', centroid: FakeCentroid.new(0, 0))
    good_record = FakeRecord.new({ 'SITE_NAME' => 'Valid Site' }, geometry)
    sequence = [RGeo::Error::InvalidGeometry.new('bad polygon'), good_record]

    stub_reader_with(sequence) do
      File.stub(:exist?, true) do
        filter = @near_filter.new(results: [true])
        importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp', tree_filter: filter)
        importer.stub(:require, nil) { importer.run }
      end
    end

    assert_equal 1, PointOfInterest.created_records.size
    assert_equal 'Valid Site', PointOfInterest.created_records.first[:site_name]
  end

  def test_run_stops_when_reader_raises_unexpected_error
    error = StandardError.new('catastrophic failure')

    stub_reader_with([error, FakeRecord.new({ 'SITE_NAME' => 'Ignored' }, FakeGeometry.new(text: '', centroid: FakeCentroid.new(0, 0)))]) do
      File.stub(:exist?, true) do
        filter = @near_filter.new
        importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp', tree_filter: filter)
        importer.stub(:require, nil) { importer.run }
      end
    end

    assert_empty PointOfInterest.created_records
  end

  def test_run_skips_record_when_create_raises_error
    geometry = FakeGeometry.new(text: 'MULTIPOLYGON(...)', centroid: FakeCentroid.new(0, 0))
    first = FakeRecord.new({ 'SITE_NAME' => 'Unlucky Site' }, geometry)
    second = FakeRecord.new({ 'SITE_NAME' => 'Lucky Site' }, geometry)

    call_count = 0
    stub_reader_with([first, second]) do
      File.stub(:exist?, true) do
        importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp', tree_filter: @near_filter.new)
        importer.stub(:require, nil) do
          PointOfInterest.stub(:create!, proc do |attrs|
                                   call_count += 1
                                   raise StandardError, 'boom' if call_count == 1

                                   PointOfInterest.created_records << attrs
                                 end) do
            importer.run
          end
        end
      end
    end

    assert_equal 1, PointOfInterest.created_records.size
    assert_equal 'Lucky Site', PointOfInterest.created_records.first[:site_name]
  end

  def test_clear_existing_records_uses_delete_all_without_where
    importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp')
      delete_calls = 0

    PointOfInterest.singleton_class.class_eval do
      if method_defined?(:where)
        alias_method :original_where, :where
        remove_method :where
      end

      define_method(:delete_all) do
        delete_calls += 1
      end
    end

    importer.send(:clear_existing_records)
    assert_equal 1, delete_calls
  ensure
    PointOfInterest.singleton_class.class_eval do
      remove_method :delete_all if method_defined?(:delete_all)
      if method_defined?(:original_where)
        alias_method :where, :original_where
        remove_method :original_where
      end
    end
  end

  def test_parse_time_handles_invalid_string
    importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp', tree_filter: @near_filter.new)
    assert_nil importer.send(:parse_time, 'not-a-time')
    assert_nil importer.send(:parse_time, nil)
    assert_nil importer.send(:parse_time, '   ')
  end

  def test_blank_to_nil_trims_values
    importer = Tasks::ImportPointsOfInterest.new(path: 'dummy.shp')
    assert_nil importer.send(:blank_to_nil, '   ')
    assert_equal 'value', importer.send(:blank_to_nil, ' value ')
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
        raise value if value.is_a?(Exception)
        value
      end

      def close; end
    end

    RGeo::Shapefile::Reader.stub(:open, proc { |*_args, &blk| blk.call(reader.new(records)) }) do
      yield
    end
  end
end

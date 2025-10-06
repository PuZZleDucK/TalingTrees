# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../../lib/import_ptv_points_of_interest'
require_relative '../../app/models/point_of_interest'

class ImportPtvPointsOfInterestTest < Minitest::Test
  def setup
    PointOfInterest.singleton_class.class_eval do
      attr_accessor :created_records unless respond_to?(:created_records)

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

      def create!(attrs)
        self.created_records ||= []
        created_records << attrs
      end
    end

    PointOfInterest.created_records = []
  end

  def teardown
    PointOfInterest.created_records = nil if PointOfInterest.respond_to?(:created_records=)
  end

  def test_run_raises_when_root_missing
    importer = Tasks::ImportPtvPointsOfInterest.new(root: '/missing')
    assert_raises(RuntimeError) { importer.run }
  end

  def test_run_imports_records_per_category
    Dir.mktmpdir do |root|
      Tasks::ImportPtvPointsOfInterest::CATEGORY_CONFIG.each do |folder, config|
        dir = File.join(root, folder)
        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, 'stops.txt'), <<~CSV)
          stop_id,stop_name,stop_lat,stop_lon
          100,#{config[:label]} Central,-37.81,144.96
          101,Invalid Lat,,144.97
        CSV
      end

      importer = Tasks::ImportPtvPointsOfInterest.new(root: root, filter: always_near_filter)
      summary = importer.run

      expected_categories = Tasks::ImportPtvPointsOfInterest::CATEGORY_CONFIG.values.map { |c| c[:category] }

      expected_categories.each do |category|
        assert_equal 1, summary[category], "Expected one record for #{category}"
      end

      created = PointOfInterest.created_records
      assert_equal expected_categories.size, created.size
      created.each do |record|
        assert_includes expected_categories, record[:category]
        assert_equal record[:herit_obj], category_label_for(record[:category])
      end
    end
  end

  def test_run_clears_previous_records_for_category
    Dir.mktmpdir do |root|
      folder = Tasks::ImportPtvPointsOfInterest::CATEGORY_CONFIG.keys.first
      dir = File.join(root, folder)
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, 'stops.txt'), <<~CSV)
        stop_id,stop_name,stop_lat,stop_lon
        200,First Import,-37.7,145.0
      CSV

      importer = Tasks::ImportPtvPointsOfInterest.new(root: root, filter: always_near_filter)
      importer.run

      PointOfInterest.created_records << { category: category_for(folder), site_name: 'Old' }

      File.write(File.join(dir, 'stops.txt'), <<~CSV)
        stop_id,stop_name,stop_lat,stop_lon
        201,Second Import,-37.8,145.1
      CSV

      PointOfInterest.created_records = PointOfInterest.created_records.dup
      importer.run

      names = PointOfInterest.created_records.map { |record| record[:site_name] }
      refute_includes names, 'Old'
      assert_includes names, 'Second Import'
      refute_includes names, 'First Import'
    end
  end

  def test_run_warns_when_stops_missing
    Dir.mktmpdir do |root|
      folder = Tasks::ImportPtvPointsOfInterest::CATEGORY_CONFIG.keys.first
      FileUtils.mkdir_p(File.join(root, folder))
      PointOfInterest.created_records = [{ category: category_for(folder), site_name: 'Legacy' }]

      importer = Tasks::ImportPtvPointsOfInterest.new(root: root, filter: always_near_filter)
      warnings = []
      importer.stub(:warn, proc { |msg| warnings << msg }) do
        importer.run
      end

      assert_equal [], PointOfInterest.created_records
      refute_empty warnings
      assert_match(/stops\.txt not found/, warnings.first)
    end
  end

  def test_run_handles_malformed_csv
    Dir.mktmpdir do |root|
      folder, config = Tasks::ImportPtvPointsOfInterest::CATEGORY_CONFIG.first
      dir = File.join(root, folder)
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, 'stops.txt'), "stop_id,stop_name,stop_lat,stop_lon\n\"broken")

      importer = Tasks::ImportPtvPointsOfInterest.new(root: root, filter: always_near_filter)
      warnings = []
      importer.stub(:warn, proc { |msg| warnings << msg }) do
        summary = importer.run
        assert_equal 0, summary[config[:category]]
      end

      assert_empty(PointOfInterest.created_records)
      refute_empty warnings
      assert_match(/Skipping/, warnings.first)
    end
  end

  def test_skips_stops_not_near_trees
    Dir.mktmpdir do |root|
      folder, config = Tasks::ImportPtvPointsOfInterest::CATEGORY_CONFIG.first
      dir = File.join(root, folder)
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, 'stops.txt'), <<~CSV)
        stop_id,stop_name,stop_lat,stop_lon
        300,Distant Stop,-37.90,145.30
      CSV

      filter = Class.new do
        attr_reader :calls

        def initialize
          @calls = []
        end

        def near?(lat, lon)
          @calls << [lat, lon]
          false
        end
      end.new

      importer = Tasks::ImportPtvPointsOfInterest.new(root: root, filter: filter)
      summary = importer.run

      assert_equal 0, summary[config[:category]]
      assert_empty PointOfInterest.created_records
      assert_equal [[-37.90, 145.30]], filter.calls
    end
  end

  def test_clear_records_falls_back_to_delete_all
    importer = Tasks::ImportPtvPointsOfInterest.new(root: Dir.mktmpdir, filter: always_near_filter)
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

    importer.send(:clear_records, 'ptv_train')
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

  private

  def category_for(folder)
    Tasks::ImportPtvPointsOfInterest::CATEGORY_CONFIG.fetch(folder)[:category]
  end

  def category_label_for(category)
    config = Tasks::ImportPtvPointsOfInterest::CATEGORY_CONFIG.values.find { |c| c[:category] == category }
    config[:label]
  end

  def always_near_filter
    @always_near_filter ||= Class.new do
      def near?(*_args)
        true
      end
    end.new
  end
end

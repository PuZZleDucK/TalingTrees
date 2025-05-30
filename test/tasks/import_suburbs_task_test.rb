# frozen_string_literal: true

require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'

SuburbRecord = Struct.new(:attributes, :geometry)

class ImportSuburbsTaskTest < Minitest::Test
  RECORDS = [
    SuburbRecord.new({ 'NAME' => 'Alpha' }, :poly1),
    SuburbRecord.new({ 'LOCALITY' => 'Beta' }, :poly2)
  ].freeze

  def setup
    Suburb.singleton_class.class_eval do
      attr_accessor :records

      def delete_all = self.records = []

      def create!(attrs) = (self.records ||= []) << attrs

      def count = (records || []).size

      def where(tree_count:)
        results = (self.records || []).select { |r| r[:tree_count] == tree_count }
        Struct.new(:records) do
          def initialize(records)
            @records = records
          end

          def delete_all
            @records.each { |rec| Suburb.records.delete(rec) }
          end
        end.new(results)
      end
    end
    Suburb.records = []

    Kernel.module_eval do
      alias_method :orig_require, :require
      def require(name)
        return true if name == 'rgeo/shapefile'

        orig_require(name)
      end
    end
    @require_patched = true

    rgeo_module = Module.new
    shapefile_module = Module.new
    reader_class = Class.new do
      def self.open(_file)
        file = Object.new
        def file.each(&blk)
          ImportSuburbsTaskTest::RECORDS.each(&blk)
        end
        yield file
      end
    end
    shapefile_module.const_set(:Reader, reader_class)
    rgeo_module.const_set(:Shapefile, shapefile_module)
    @previous_rgeo = Object.const_get(:RGeo) if Object.const_defined?(:RGeo)
    Object.send(:remove_const, :RGeo) if Object.const_defined?(:RGeo)
    Object.const_set(:RGeo, rgeo_module)

    require File.expand_path('../../lib/import_suburbs', __dir__)

    @orig_tree_count = Tasks::ImportSuburbs.instance_method(:tree_count_for_polygon)
    Tasks::ImportSuburbs.define_method(:tree_count_for_polygon) do |polygon|
      polygon == :poly1 ? 1 : 0
    end

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/import_suburbs.rake', __dir__)
  end

  def teardown
    Suburb.records = []
    Object.send(:remove_const, :RGeo)
    Object.const_set(:RGeo, @previous_rgeo) if @previous_rgeo
    Tasks::ImportSuburbs.define_method(:tree_count_for_polygon, @orig_tree_count)
    return unless @require_patched

    Kernel.module_eval do
      alias_method :require, :orig_require
      remove_method :orig_require
    end
  end

  def test_creates_suburb_records
    Rake.application['db:import_suburbs'].invoke('dummy')
    names = Suburb.records.map { |r| r[:name] }
    assert_includes names, 'Alpha'
    refute_includes names, 'Beta'
  end

  def test_saves_tree_count
    Rake.application['db:import_suburbs'].invoke('dummy')
    record = Suburb.records.find { |r| r[:name] == 'Alpha' }
    assert_equal 1, record[:tree_count]
  end
end

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
    Object.const_set(:RGeo, rgeo_module)

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/import_suburbs.rake', __dir__)
  end

  def teardown
    Suburb.records = []
    Object.send(:remove_const, :RGeo)
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
    assert_includes names, 'Beta'
  end
end

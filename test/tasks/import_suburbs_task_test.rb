# frozen_string_literal: true

require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'

class ImportSuburbsTaskTest < Minitest::Test
  class << self
    def setup_suburb_class
      Suburb.class_eval do
        class << self
          attr_accessor :records

          def delete_all
            self.records = []
          end

          def create!(attrs)
            self.records ||= []
            self.records << attrs
          end

          def columns_hash
            { 'boundary' => Struct.new(:type).new(:text) }
          end
        end
      end
    end
  end

  def setup
    self.class.setup_suburb_class
    Suburb.records = []

    Kernel.module_eval do
      alias_method :orig_require, :require
      def require(name)
        return true if name == 'rgeo/shapefile'

        orig_require(name)
      end
    end
    @require_patched = true

    reader_class = Class.new do
      def self.open(_path)
        record = Struct.new(:attributes, :geometry).new({ 'LOC_NAME' => 'Foo' }, Struct.new(:as_text).new('POLY'))
        yield [record]
      end
    end
    shapefile_module = Module.new
    shapefile_module.const_set(:Reader, reader_class)
    rgeo_module = Module.new
    rgeo_module.const_set(:Shapefile, shapefile_module)
    Object.const_set(:RGeo, rgeo_module)

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/import_suburbs.rake', __dir__)
  end

  def teardown
    Suburb.records = nil
    if @require_patched
      Kernel.module_eval do
        alias_method :require, :orig_require
        remove_method :orig_require
      end
    end
    Object.send(:remove_const, :RGeo) if Object.const_defined?(:RGeo)
  end

  def test_creates_suburb_records
    Rake.application['db:import_suburbs'].invoke
    assert_equal 1, Suburb.records.length
    rec = Suburb.records.first
    assert_equal 'Foo', rec[:name]
    assert_equal 'POLY', rec[:boundary]
  end

  def test_raises_when_file_missing
    assert_raises RuntimeError do
      Rake.application['db:import_suburbs'].invoke('missing.shp')
    end
  end
end

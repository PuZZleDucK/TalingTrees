# frozen_string_literal: true

require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'
require 'tmpdir'
require 'json'
require 'active_support/core_ext/object/blank'

class ImportTreesTaskTest < Minitest::Test
  class << self
    def setup_tree_class
      Tree.class_eval do
        class << self
          attr_accessor :records

          def find_or_initialize_by(treedb_com_id:)
            self.records ||= {}
            obj = self.records[treedb_com_id] ||= new(
              name: nil,
              treedb_com_id: treedb_com_id,
              treedb_common_name: nil,
              treedb_genus: nil,
              treedb_family: nil,
              treedb_diameter: nil,
              treedb_date_planted: nil,
              treedb_age_description: nil,
              treedb_useful_life_expectency_value: nil,
              treedb_precinct: nil,
              treedb_located_in: nil,
              treedb_uploaddate: nil,
              treedb_lat: nil,
              treedb_long: nil,
              llm_sustem_prompt: nil
            )
            obj.define_singleton_method(:new_record?) { true }
            obj.define_singleton_method(:changed?) { true }
            obj.define_singleton_method(:save!) { nil }
            obj
          end
        end
      end
    end
  end

  def setup
    self.class.setup_tree_class
    Tree.records = {}

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/import_trees.rake', __dir__)
  end

  def teardown
    Tree.records = nil
  end

  def test_respects_count_parameter
    Dir.mktmpdir do |dir|
      data = {
        'total_count' => 3,
        'records' => 3.times.map { |i| { 'record' => { 'fields' => { 'com_id' => i.to_s } } } }
      }
      File.write(File.join(dir, 'trees_0.json'), JSON.generate(data))

      Rake.application['db:import_trees'].invoke('2', dir)

      assert_equal 2, Tree.records.size
    end
  end
end

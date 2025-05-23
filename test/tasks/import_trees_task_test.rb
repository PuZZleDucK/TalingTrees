# frozen_string_literal: true

require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'
require 'stringio'
require 'uri'
require 'cgi'
require 'open-uri'
require 'net/http'
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

    @responses = {}

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/import_trees.rake', __dir__)
  end

  def teardown
    Tree.records = nil
  end

  def stub_response(limit, offset, total)
    records = (offset...(offset + limit)).map do |i|
      break if i >= total

      { 'record' => { 'fields' => { 'com_id' => i.to_s } } }
    end.compact
    { 'total_count' => total, 'records' => records }.to_json
  end

  def test_respects_count_parameter
    total = 3
    method_ref = method(:stub_response)
    Net::HTTP.singleton_class.class_eval do
      alias_method :orig_get, :get
      define_method(:get) do |uri|
        if uri.to_s.start_with?('http')
          query = URI.parse(uri.to_s).query
          params = CGI.parse(query)
          limit = params['limit'].first.to_i
          offset = params['offset'].first.to_i
          method_ref.call(limit, offset, total)
        else
          orig_get(uri)
        end
      end
    end

    Rake.application['db:import_trees'].invoke('2')

    assert_equal 2, Tree.records.size
  ensure
    Net::HTTP.singleton_class.class_eval do
      remove_method :get
      alias_method :get, :orig_get
      remove_method :orig_get
    end
  end
end

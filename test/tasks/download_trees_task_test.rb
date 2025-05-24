# frozen_string_literal: true

require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'
require 'tmpdir'
require 'uri'
require 'cgi'
require 'net/http'

class DownloadTreesTaskTest < Minitest::Test
  def setup
    @responses = {}

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/download_trees.rake', __dir__)
  end

  def stub_response(limit, offset, total)
    records = (offset...(offset + limit)).map do |i|
      break if i >= total

      { 'record' => { 'fields' => { 'com_id' => i.to_s } } }
    end.compact
    { 'total_count' => total, 'records' => records }.to_json
  end

  def test_writes_json_files
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

    Dir.mktmpdir do |dir|
      Rake.application['db:download_trees'].invoke('2', dir)
      files = Dir[File.join(dir, '*.json')]
      assert_equal 1, files.length
      data = JSON.parse(File.read(files.first))
      assert_equal 2, data['records'].length
    end
  ensure
    Net::HTTP.singleton_class.class_eval do
      remove_method :get
      alias_method :get, :orig_get
      remove_method :orig_get
    end
  end
end

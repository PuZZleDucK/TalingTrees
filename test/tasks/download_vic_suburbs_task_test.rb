# frozen_string_literal: true

require_relative '../test_helper'
require 'rake'
require 'minitest/autorun'
require 'tmpdir'
require 'stringio'

class DownloadVicSuburbsTaskTest < Minitest::Test
  def setup
    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path('../../lib/tasks/download_vic_suburbs.rake', __dir__)

    require 'open-uri'
    method_ref = method(:stub_open)
    URI.singleton_class.class_eval do
      alias_method :orig_open, :open
      define_method(:open) do |url, *args, &blk|
        if url == 'http://example.com/vic.zip'
          io = method_ref.call
          if blk
            begin
              blk.call(io)
            ensure
              io.close if io.respond_to?(:close)
            end
          else
            io
          end
        else
          orig_open(url, *args, &blk)
        end
      end
    end
  end

  def teardown
    URI.singleton_class.class_eval do
      remove_method :open
      alias_method :open, :orig_open
      remove_method :orig_open
    end
  end

  def stub_open
    StringIO.new('zipdata')
  end

  def test_downloads_zip_file
    Dir.mktmpdir do |dir|
      Rake.application['db:download_vic_suburbs'].invoke('http://example.com/vic.zip', dir, 'vic.zip')
      file = File.join(dir, 'vic.zip')
      assert File.exist?(file)
      assert_equal 'zipdata', File.read(file)
    end
  end
end

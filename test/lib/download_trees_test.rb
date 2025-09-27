# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../lib/download_trees'

class DownloadTreesTest < Minitest::Test
  def test_remaining_without_count_returns_default
    task = Tasks::DownloadTrees.new
    assert_equal Tasks::DownloadTrees::DEFAULT_LIMIT, task.send(:remaining, 0)
  end

  def test_remaining_with_count_limits_properly
    task = Tasks::DownloadTrees.new(count: 50)
    assert_equal 50, task.send(:remaining, 0)
    assert_equal 10, task.send(:remaining, 40)
    assert_equal 0, task.send(:remaining, 60)
  end

  def test_stop_returns_true_when_limit_reached
    task = Tasks::DownloadTrees.new(count: 5)
    assert task.send(:stop?, 5)
    refute task.send(:stop?, 4)
  end

  def test_run_writes_records_until_limit
    responses = [
      { 'total_count' => 5, 'records' => [1, 2] },
      { 'total_count' => 5, 'records' => [3] }
    ]
    writes = []

    task = Tasks::DownloadTrees.new(count: 3, dir: 'tmpdir')
    fetcher = proc { |_limit, _offset| responses.shift || { 'total_count' => 5, 'records' => [] } }

    task.stub(:fetch_records, fetcher) do
      FileUtils.stub(:mkdir_p, nil) do
        File.stub(:write, ->(path, body) { writes << [path, body] }) do
          task.run
        end
      end
    end

    assert_equal 2, writes.length
    assert_equal 'tmpdir/trees_0.json', writes[0].first
    assert_includes writes[0].last, '"records"'
  end

  def test_initialize_ignores_non_positive_counts
    task = Tasks::DownloadTrees.new(count: 0)
    assert_equal Tasks::DownloadTrees::DEFAULT_LIMIT, task.send(:remaining, 0)
  end
end

# frozen_string_literal: true

require_relative 'test_helper'
require 'minitest/autorun'

Dir[File.join(__dir__, '**/*_test.rb')].each { |f| require_relative f }

Minitest.after_run do
  coverage = Coverage.result
  total_covered = 0
  total_lines = 0
  File.open('coverage.txt', 'w') do |f|
    coverage.each do |file, data|
      covered_lines = data.count { |line| line&.positive? }
      total_lines_file = data.size
      percent = total_lines_file.positive? ? (covered_lines.to_f / total_lines_file * 100).round(2) : 0
      f.puts "#{file}: #{percent}% (#{covered_lines}/#{total_lines_file})"
      total_covered += covered_lines
      total_lines += total_lines_file
    end
    total_percent = total_lines.positive? ? (total_covered.to_f / total_lines * 100).round(2) : 0
    f.puts "TOTAL: #{total_percent}% (#{total_covered}/#{total_lines})"
  end

  rubocop_output = `bundle exec rubocop 2>&1`
  File.write('rubocop_report.txt', rubocop_output)

  bundler_audit_output = `bundle exec bundler-audit check 2>&1`
  File.write('bundler_audit_report.txt', bundler_audit_output)

  brakeman_output = `bundle exec brakeman -q 2>&1`
  File.write('brakeman_report.txt', brakeman_output)
end

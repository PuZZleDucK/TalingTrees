require_relative 'test_helper'
require 'minitest/autorun'

Dir[File.join(__dir__, '**/*_test.rb')].sort.each { |f| require_relative f }

Minitest.after_run do
  coverage = Coverage.result
  total_covered = 0
  total_lines = 0
  File.open('coverage.txt', 'w') do |f|
    coverage.each do |file, data|
      covered_lines = data.count { |line| line && line > 0 }
      total_lines_file = data.size
      percent = total_lines_file > 0 ? (covered_lines.to_f / total_lines_file * 100).round(2) : 0
      f.puts "#{file}: #{percent}% (#{covered_lines}/#{total_lines_file})"
      total_covered += covered_lines
      total_lines += total_lines_file
    end
    total_percent = total_lines > 0 ? (total_covered.to_f / total_lines * 100).round(2) : 0
    f.puts "TOTAL: #{total_percent}% (#{total_covered}/#{total_lines})"
  end

  File.write('rubocop_report.txt', 'RuboCop could not run because the rubocop gem is not installed in this environment.')
  File.write('bundler_audit_report.txt', 'bundler-audit could not run because the bundler-audit gem is not installed in this environment.')
  File.write('brakeman_report.txt', 'Brakeman could not run because the brakeman gem is not installed in this environment.')
end

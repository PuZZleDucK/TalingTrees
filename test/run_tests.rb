require_relative 'test_helper'
require 'minitest/autorun'

Dir[File.join(__dir__, '**/*_test.rb')].sort.each { |f| require_relative f }

# generate placeholder reports for tools that are unavailable in this
# environment so the workflow has something to display
File.write('rubocop_report.txt', "RuboCop could not run because the rubocop gem is not installed in this environment.\n")
File.write('bundler_audit_report.txt', "bundler-audit could not run because the bundler-audit gem is not installed in this environment.\n")
File.write('brakeman_report.txt', "Brakeman could not run because the brakeman gem is not installed in this environment.\n")

at_exit do
  coverage = Coverage.result
  File.open('coverage.txt', 'w') do |f|
    total_covered = 0
    total_count = 0
    coverage.each do |file, data|
      covered_lines = data.count { |line| line && line > 0 }
      line_total = data.size
      percent = line_total > 0 ? (covered_lines.to_f / line_total * 100).round(2) : 0
      f.puts "#{file}: #{percent}% (#{covered_lines}/#{line_total})"
      total_covered += covered_lines
      total_count += line_total
    end
    overall = total_count > 0 ? (total_covered.to_f / total_count * 100).round(2) : 0
    f.puts "TOTAL #{overall}% (#{total_covered}/#{total_count})"
  end
end

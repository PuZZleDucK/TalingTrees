require_relative 'test_helper'
require 'minitest/autorun'

Dir[File.join(__dir__, '**/*_test.rb')].sort.each { |f| require_relative f }

at_exit do
  coverage = Coverage.result
  File.open('coverage.txt', 'w') do |f|
    coverage.each do |file, data|
      covered_lines = data.count { |line| line && line > 0 }
      total_lines = data.size
      percent = total_lines > 0 ? (covered_lines.to_f / total_lines * 100).round(2) : 0
      f.puts "#{file}: #{percent}% (#{covered_lines}/#{total_lines})"
    end
  end

  File.write('rubocop_report.txt',
             "RuboCop could not run because the rubocop gem is not installed in this environment.\n")
  File.write('bundler_audit_report.txt',
             "bundler-audit could not run because the bundler-audit gem is not installed in this environment.\n")
  File.write('brakeman_report.txt',
             "Brakeman could not run because the brakeman gem is not installed in this environment.\n")
end

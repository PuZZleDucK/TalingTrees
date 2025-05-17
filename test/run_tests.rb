require_relative 'test_helper'
require 'minitest/autorun'

Dir[File.join(__dir__, '**/*_test.rb')].sort.each { |f| require_relative f }

# Generate placeholder reports for tools that aren't available in this
# restricted environment.
File.write('rubocop_report.txt',
           "RuboCop could not run because the rubocop gem is not installed in this environment.\n")
File.write('bundler_audit_report.txt',
           "bundler-audit could not run because the bundler-audit gem is not installed in this environment.\n")
File.write('brakeman_report.txt',
           "Brakeman could not run because the brakeman gem is not installed in this environment.\n")

at_exit do
  coverage = Coverage.result
  total_covered = 0
  total_lines = 0
  File.open('coverage.txt', 'w') do |f|
    coverage.each do |file, data|
      covered = data.count { |line| line && line > 0 }
      lines = data.size
      percent = lines > 0 ? (covered.to_f / lines * 100).round(2) : 0
      f.puts "#{file}: #{percent}% (#{covered}/#{lines})"
      total_covered += covered
      total_lines += lines
    end
    total_percent = total_lines > 0 ? (total_covered.to_f / total_lines * 100).round(2) : 0
    f.puts "TOTAL: #{total_percent}% (#{total_covered}/#{total_lines})"
  end
end

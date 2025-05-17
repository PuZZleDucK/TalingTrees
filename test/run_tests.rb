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
end

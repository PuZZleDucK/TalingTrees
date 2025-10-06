# frozen_string_literal: true

require_relative '../import_points_of_interest'
require_relative '../import_ptv_points_of_interest'

namespace :db do
  desc 'Import heritage register data into points_of_interest'
  task import_points_of_interest: :environment do
    importer = Tasks::ImportPointsOfInterest.new
    importer.run
    count = if PointOfInterest.respond_to?(:where)
              PointOfInterest.where(category: 'heritage').count
            else
              Array(PointOfInterest.records).count
            end
    puts "Imported #{count} heritage points of interest"
  end

  desc 'Import PTV stop data into points_of_interest'
  task import_ptv_points_of_interest: :environment do
    importer = Tasks::ImportPtvPointsOfInterest.new
    summary = importer.run
    summary.each do |category, count|
      puts "Imported #{count} #{category} points"
    end

    if PointOfInterest.respond_to?(:where)
      total = PointOfInterest.where(category: summary.keys).count
      puts "Total PTV points stored: #{total}"
    end
  end
end

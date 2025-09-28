# frozen_string_literal: true

require_relative '../import_points_of_interest'

namespace :db do
  desc 'Import heritage register data into points_of_interest'
  task import_points_of_interest: :environment do
    importer = Tasks::ImportPointsOfInterest.new
    importer.run
    puts "Imported \\#{PointOfInterest.count} points of interest"
  end
end

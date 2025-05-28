# frozen_string_literal: true

require_relative '../import_suburbs'

namespace :db do
  desc 'Import Victorian suburb data from shapefile'
  task :import_suburbs, [:file] => :environment do |_, args|
    Tasks::ImportSuburbs.new(file: args[:file]).run
  end
end

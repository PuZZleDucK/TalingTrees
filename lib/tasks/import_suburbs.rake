# frozen_string_literal: true

require_relative '../import_suburbs'

namespace :db do
  desc 'Import Victorian suburb data from shapefiles'
  task :import_suburbs, [:path] => :environment do |_, args|
    Tasks::ImportSuburbs.new(path: args[:path]).run
  end
end

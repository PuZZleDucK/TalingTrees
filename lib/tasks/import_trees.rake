# frozen_string_literal: true

require_relative '../import_trees'

namespace :db do
  desc 'Import tree data from Melbourne dataset'
  task :import_trees, [:count] => :environment do |_, args|
    Tasks::ImportTrees.new(count: args[:count]).run
  end
end

# frozen_string_literal: true

require_relative '../import_trees'

namespace :db do
  desc 'Import tree data from downloaded files'
  task :import_trees, %i[count dir] => :environment do |_, args|
    Tasks::ImportTrees.new(count: args[:count], dir: args[:dir]).run
  end
end

# frozen_string_literal: true

require_relative '../download_trees'

namespace :db do
  desc 'Download tree data from Melbourne dataset'
  task :download_trees, [:count, :dir] => :environment do |_, args|
    Tasks::DownloadTrees.new(count: args[:count], dir: args[:dir]).run
  end
end

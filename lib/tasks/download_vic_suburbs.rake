# frozen_string_literal: true

require_relative '../download_vic_suburbs'

namespace :db do
  desc 'Download Victorian suburb shapefile dataset from data.gov.au'
  task :download_vic_suburbs, %i[url dir filename] => :environment do |_, args|
    Tasks::DownloadVicSuburbs.new(
      url: args[:url],
      dir: args[:dir],
      filename: args[:filename]
    ).run
  end
end

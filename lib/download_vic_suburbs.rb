# frozen_string_literal: true

module Tasks
  # Downloads the Victorian locality shapefile dataset from data.gov.au.
  class DownloadVicSuburbs
    DEFAULT_URL = 'https://data.gov.au/data/dataset/vic-localities/resource/latest/download/MAY25_-_VIC_-_Localities_-_Esri_Shapefiles_-_GDA94.zip'
    DEFAULT_DIR = File.expand_path('../data/suburbs', __dir__)
    DEFAULT_FILENAME = 'vic_suburbs.zip'

    def initialize(url: DEFAULT_URL, dir: DEFAULT_DIR, filename: DEFAULT_FILENAME)
      @url = url || DEFAULT_URL
      @dir = dir || DEFAULT_DIR
      @filename = filename || DEFAULT_FILENAME
    end

    def run
      require 'fileutils'
      require 'open-uri'

      FileUtils.mkdir_p(@dir)
      filepath = File.join(@dir, @filename)
      URI.open(@url) do |remote|
        File.open(filepath, 'wb') { |f| f.write(remote.read) }
      end
    end
  end
end

# frozen_string_literal: true

require_relative 'import_trees'

module Tasks
  # Downloads tree data from the Melbourne open dataset into JSON files.
  class DownloadTrees
    BASE_URL = Tasks::ImportTrees::BASE_URL
    DEFAULT_LIMIT = Tasks::ImportTrees::DEFAULT_LIMIT
    DEFAULT_DIR = Tasks::ImportTrees::DEFAULT_DIR

    def initialize(count: nil, dir: DEFAULT_DIR)
      @count = count&.to_i
      @count = nil if @count && @count <= 0
      @dir = dir || DEFAULT_DIR
    end

    def run
      require 'net/http'
      require 'json'
      require 'fileutils'

      FileUtils.mkdir_p(@dir)
      offset = 0
      downloaded = 0
      total = nil

      loop do
        current_limit = [DEFAULT_LIMIT, remaining(downloaded)].min
        json = fetch_records(current_limit, offset)
        total ||= json['total_count'].to_i
        records = json['records'] || []
        break if records.empty?

        File.write(File.join(@dir, "trees_#{offset}.json"), JSON.pretty_generate(json))
        downloaded += records.size
        break if stop?(downloaded)

        offset += current_limit
        break if offset >= total
      end
    end

    private

    def fetch_records(limit, offset)
      url = "#{BASE_URL}?#{URI.encode_www_form(limit: limit, offset: offset)}"
      puts "Fetching #{url}"
      data = Net::HTTP.get(URI(url))
      JSON.parse(data)
    end

    def remaining(downloaded)
      return DEFAULT_LIMIT unless @count

      remaining = @count - downloaded
      [remaining, 0].max
    end

    def stop?(downloaded)
      @count && downloaded >= @count
    end
  end
end

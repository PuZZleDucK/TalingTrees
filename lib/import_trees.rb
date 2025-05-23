# frozen_string_literal: true

module Tasks
  # Imports tree data from the Melbourne open dataset.
  class ImportTrees
    BASE_URL = 'https://data.melbourne.vic.gov.au/api/v2/catalog/datasets/trees-with-species-and-dimensions-urban-forest/records'
    DEFAULT_LIMIT = 100

    def initialize(count: nil)
      @count = count&.to_i
      @count = nil if @count && @count <= 0
    end

    def run
      require 'net/http'
      require 'json'
      offset = 0
      imported = 0
      total = nil

      loop do
        current_limit = [DEFAULT_LIMIT, remaining(imported)].min
        json = fetch_records(current_limit, offset)
        total ||= json['total_count'].to_i
        records = json['records'] || []
        break if records.empty?

        records.each do |record|
          import_record(record.dig('record', 'fields') || {})
          imported += 1
          break if stop?(imported)
        end
        break if stop?(imported)

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

    # rubocop:disable Metrics/AbcSize
    def import_record(fields)
      tree = Tree.find_or_initialize_by(treedb_com_id: fields['com_id'])

      tree.name = nil if tree.name.blank?
      tree.treedb_common_name ||= fields['common_name']
      tree.treedb_genus ||= fields['genus']
      tree.treedb_family ||= fields['family']
      tree.treedb_diameter ||= fields['diameter_breast_height']
      tree.treedb_date_planted ||= fields['date_planted']
      tree.treedb_age_description ||= fields['age_description']
      tree.treedb_useful_life_expectency_value ||= fields['useful_life_expectency_value']
      tree.treedb_precinct ||= fields['precinct']
      tree.treedb_located_in ||= fields['located_in']
      tree.treedb_uploaddate ||= fields['uploaddate']
      tree.treedb_lat ||= fields['latitude']
      tree.treedb_long ||= fields['longitude']

      tree.llm_sustem_prompt = nil if tree.new_record?
      tree.save! if tree.changed?
    end
    # rubocop:enable Metrics/AbcSize

    def remaining(imported)
      return DEFAULT_LIMIT unless @count

      remaining = @count - imported
      [remaining, 0].max
    end

    def stop?(imported)
      @count && imported >= @count
    end
  end
end

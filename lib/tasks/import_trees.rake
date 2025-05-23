# frozen_string_literal: true

namespace :db do
  desc 'Import tree data from Melbourne dataset'
  task :import_trees, [:count] => :environment do |_, args|
    require 'open-uri'
    require 'json'

    count = args[:count]&.to_i
    count = nil if count && count <= 0

    base_url = 'https://data.melbourne.vic.gov.au/api/v2/catalog/datasets/trees-with-species-and-dimensions-urban-forest/records'
    # The dataset API rejects requests with a very large limit. The
    # documented maximum is 100 records per request, so fetch in smaller
    # batches to avoid HTTP 400 errors.
    limit = 100
    offset = 0
    total = nil
    imported = 0

    loop do
      current_limit = limit
      current_limit = count - imported if count && (count - imported) < current_limit
      url = "#{base_url}?#{URI.encode_www_form(limit: current_limit, offset: offset)}"
      puts "Fetching #{url}"
      begin
        data = URI.open(url).read
      rescue OpenURI::HTTPError => e
        warn "Failed to fetch #{url}: #{e.message}"
        break
      end
      json = JSON.parse(data)
      total ||= json['total_count'].to_i
      records = json['records'] || []
      break if records.empty?

      records.each do |record|
        fields = record.dig('record', 'fields') || {}

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
        imported += 1
        break if count && imported >= count
      end
      break if count && imported >= count

      offset += current_limit
      break if offset >= total
    end
  end
end

namespace :db do
  desc 'Clear all trees and import from Melbourne dataset'
  task import_trees: :environment do
    require 'open-uri'
    require 'json'

    puts 'Clearing existing trees...'
    Tree.delete_all

    base_url = 'https://data.melbourne.vic.gov.au/api/v2/catalog/datasets/trees-with-species-and-dimensions-urban-forest/records'
    limit = 1000
    offset = 0
    total = nil

    loop do
      url = "#{base_url}?#{URI.encode_www_form(limit: limit, offset: offset)}"
      puts "Fetching #{url}"
      data = URI.open(url).read
      json = JSON.parse(data)
      total ||= json['total_count'].to_i
      records = json['records'] || []
      break if records.empty?

      records.each do |record|
        fields = record.dig('record', 'fields') || {}
        Tree.create!(
          name: fields['common_name'] || fields['scientific_name'] || 'Unknown',
          treedb_com_id: fields['com_id'],
          treedb_common_name: fields['common_name'],
          treedb_genus: fields['genus'],
          treedb_family: fields['family'],
          treedb_diameter: fields['diameter_breast_height'],
          treedb_date_planted: fields['date_planted'],
          treedb_age_description: fields['age_description'],
          treedb_useful_life_expectency_value: fields['useful_life_expectency_value'],
          treedb_precinct: fields['precinct'],
          treedb_located_in: fields['located_in'],
          treedb_uploaddate: fields['uploaddate'],
          treedb_lat: fields['latitude'],
          treedb_long: fields['longitude'],
          llm_model: nil,
          llm_sustem_prompt: nil
        )
      end

      offset += limit
      break if offset >= total
    end
  end
end

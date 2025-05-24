# frozen_string_literal: true

module Tasks
  # Imports tree data from the Melbourne open dataset.
  class ImportTrees
    BASE_URL = 'https://data.melbourne.vic.gov.au/api/v2/catalog/datasets/trees-with-species-and-dimensions-urban-forest/records'
    DEFAULT_LIMIT = 100
    DEFAULT_DIR = File.expand_path('../data/trees', __dir__)

    FIELD_MAP = {
      'common_name' => :treedb_common_name,
      'genus' => :treedb_genus,
      'family' => :treedb_family,
      'diameter_breast_height' => :treedb_diameter,
      'date_planted' => :treedb_date_planted,
      'age_description' => :treedb_age_description,
      'useful_life_expectency_value' => :treedb_useful_life_expectency_value,
      'precinct' => :treedb_precinct,
      'located_in' => :treedb_located_in,
      'uploaddate' => :treedb_uploaddate,
      'latitude' => :treedb_lat,
      'longitude' => :treedb_long
    }.freeze

    def initialize(count: nil, dir: DEFAULT_DIR)
      @count = count&.to_i
      @count = nil if @count && @count <= 0
      @dir = dir || DEFAULT_DIR
    end

    def run
      require 'json'
      Dir.glob(File.join(@dir, '*.json')).sort.each do |file|
        json = JSON.parse(File.read(file))
        records = json['records'] || []
        records.each do |record|
          import_record(record.dig('record', 'fields') || {})
          @imported = (@imported || 0) + 1
          return if stop?(@imported)
        end
        return if stop?(@imported)
      end
    end

    private

    def import_record(fields)
      tree = Tree.find_or_initialize_by(treedb_com_id: fields['com_id'])
      tree.name = nil if tree.name.blank?

      FIELD_MAP.each do |source, attr|
        value = fields[source]
        next if value.nil? || value.to_s.strip.empty?

        current = tree.public_send(attr)
        tree.public_send("#{attr}=", value) if current.blank?
      end

      tree.llm_sustem_prompt = nil if tree.new_record?
      tree.save! if tree.changed?
    end

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

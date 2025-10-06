# frozen_string_literal: true

require 'csv'
require_relative 'near_tree_filter'

module Tasks
  # Imports PTV stop data as point-of-interest records grouped by transport mode.
  class ImportPtvPointsOfInterest
    DEFAULT_ROOT = File.expand_path('../data/ptv', __dir__)

    CATEGORY_CONFIG = {
      '2 Metropolitan Train' => { category: 'ptv_train', label: 'Train Station' },
      '3 Metropolitan Tram' => { category: 'ptv_tram', label: 'Tram Stop' },
      '4 Metropolitan Bus' => { category: 'ptv_bus', label: 'Bus Stop' },
      '10 Interstate' => { category: 'ptv_interstate', label: 'Interstate Coach Stop' },
      '11 SkyBus' => { category: 'ptv_skybus', label: 'SkyBus Stop' }
    }.freeze

    def initialize(root: DEFAULT_ROOT, filter: nil)
      @root = root
      @filter = filter
    end

    def run
      raise "PTV data directory not found at #{@root}" unless Dir.exist?(@root)

      @filter ||= Tasks::NearTreeFilter.new

      summary = {}
      CATEGORY_CONFIG.each do |folder, config|
        summary[config[:category]] = import_folder(folder, config)
      end
      summary
    end

    private

    def import_folder(folder_name, config)
      path = File.join(@root, folder_name)
      stops_path = File.join(path, 'stops.txt')

      unless Dir.exist?(path)
        clear_records(config[:category])
        return 0
      end

      unless File.exist?(stops_path)
        warn "Skipping #{folder_name}: stops.txt not found"
        clear_records(config[:category])
        return 0
      end

      clear_records(config[:category])
      created = 0

      CSV.foreach(stops_path, headers: true, encoding: 'bom|utf-8') do |row|
        name = row['stop_name'].to_s.strip
        lat = float_or_nil(row['stop_lat'])
        lon = float_or_nil(row['stop_lon'])

        next if name.empty? || lat.nil? || lon.nil?
        next unless near_any_tree?(lat, lon)

        create_point!(
          site_name: name,
          centroid_lat: lat,
          centroid_long: lon,
          external_id: external_id(folder_name, row['stop_id']),
          category: config[:category],
          herit_obj: config[:label]
        )
        created += 1
      end

      created
    rescue CSV::MalformedCSVError => e
      warn "Skipping #{folder_name}: #{e.message}"
      0
    end

    def float_or_nil(value)
      return if value.nil?

      Float(value)
    rescue ArgumentError, TypeError
      nil
    end

    def external_id(folder, stop_id)
      "#{folder}:#{stop_id}".strip
    end

    def create_point!(attrs)
      PointOfInterest.create!({
                                 vhr_number: nil,
                                 vhi_number: nil,
                                 hermes_number: nil,
                                 ufi: nil,
                                 ufi_created_at: nil,
                                 boundary: nil
                               }.merge(attrs))
    end

    def near_any_tree?(lat, lon)
      return true unless @filter

      if @filter.near?(lat, lon)
        true
      else
        false
      end
    rescue StandardError
      false
    end

    def clear_records(category)
      if PointOfInterest.respond_to?(:where)
        PointOfInterest.where(category: category).delete_all
      elsif PointOfInterest.respond_to?(:delete_all)
        PointOfInterest.delete_all
      end
    end
  end
end

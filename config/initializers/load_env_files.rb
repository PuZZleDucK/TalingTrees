# frozen_string_literal: true

# Minimal .env loader so Rails picks up local configuration without external gems.
module EnvFileLoader
  module_function

  def load!
    @loaded_sources ||= {}
    load_file(Rails.root.join('.env'), override: false, source: :env)
    load_file(Rails.root.join('.env.local'), override: true, source: :local)
  end

  def load_file(path, override:, source:)
    return unless File.exist?(path)

    File.foreach(path) do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')

      line = line.sub(/export\s+/, '')
      key, value = line.split('=', 2)
      next unless key && value

      key = key.strip
      value = value.strip
      value = value[1..-2] if value.start_with?('"') && value.end_with?('"')
      value = value[1..-2] if value.start_with?("'") && value.end_with?("'")

      if ENV.key?(key)
        next unless override && loaded_from_file?(key)
      end

      ENV[key] = value
      record_source(key, source)
    end
  end

  def loaded_from_file?(key)
    @loaded_sources && @loaded_sources.key?(key)
  end

  def record_source(key, source)
    @loaded_sources ||= {}
    @loaded_sources[key] = source
  end
end

EnvFileLoader.load!

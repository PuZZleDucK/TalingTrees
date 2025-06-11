# frozen_string_literal: true

Rails.application.config.after_initialize do
  next unless ActiveRecord::Base.connected?

  adapter = ActiveRecord::Base.connection.adapter_name.downcase
  next unless adapter.include?('sqlite')

  begin
    ActiveRecord::Base.connection.execute("SELECT load_extension('mod_spatialite')")
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.warn("Could not load SpatiaLite extension: #{e.message}")
  end
end

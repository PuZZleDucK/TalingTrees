# frozen_string_literal: true

# Adds a suburbs table with optional geometry support via SpatiaLite.
class CreateSuburbs < ActiveRecord::Migration[7.1]
  def up
    create_table :suburbs do |t|
      t.string :name
    end

    begin
      execute "SELECT load_extension('mod_spatialite');"
      execute 'SELECT InitSpatialMetaData();'
      execute "SELECT AddGeometryColumn('suburbs', 'boundary', 4326, 'POLYGON', 2);"
      execute "SELECT CreateSpatialIndex('suburbs', 'boundary');"
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn("SpatiaLite not available: #{e.message}")
      add_column :suburbs, :boundary, :text
    end
  end

  def down
    drop_table :suburbs
  end
end

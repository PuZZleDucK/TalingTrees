# frozen_string_literal: true

class CreatePointsOfInterest < ActiveRecord::Migration[7.2]
  def change
    create_table :points_of_interest do |t|
      t.string :site_name, null: false
      t.string :vhr_number
      t.string :vhi_number
      t.string :herit_obj
      t.string :hermes_number
      t.bigint :ufi
      t.integer :external_id
      t.datetime :ufi_created_at
      t.float :centroid_lat
      t.float :centroid_long
      t.text :boundary

      t.timestamps
    end

    add_index :points_of_interest, :site_name
    add_index :points_of_interest, :vhr_number
    add_index :points_of_interest, :ufi, unique: true
  end
end

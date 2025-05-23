# frozen_string_literal: true

class AddLatLongToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :lat, :float
    add_column :users, :long, :float
  end
end

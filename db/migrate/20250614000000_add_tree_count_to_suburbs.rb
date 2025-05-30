# frozen_string_literal: true

# Adds a tree_count column to the suburbs table.
class AddTreeCountToSuburbs < ActiveRecord::Migration[7.1]
  def change
    add_column :suburbs, :tree_count, :integer, default: 0, null: false
  end
end

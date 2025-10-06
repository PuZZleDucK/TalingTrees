# frozen_string_literal: true

class AddCategoryToPointsOfInterest < ActiveRecord::Migration[7.1]
  def change
    add_column :points_of_interest, :category, :string
    add_index :points_of_interest, :category

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE points_of_interest SET category = 'heritage' WHERE category IS NULL
        SQL
      end
    end
  end
end

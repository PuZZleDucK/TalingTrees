# frozen_string_literal: true

class CreateTrees < ActiveRecord::Migration[7.1]
  def change
    create_table :trees do |t|
      t.string :name
      t.string :treedb_com_id
      t.string :treedb_common_name
      t.string :treedb_genus
      t.string :treedb_family
      t.string :treedb_diameter
      t.date   :treedb_date_planted
      t.string :treedb_age_description
      t.string :treedb_useful_life_expectency_value
      t.string :treedb_precinct
      t.string :treedb_located_in
      t.date   :treedb_uploaddate
      t.float  :treedb_lat
      t.float  :treedb_long
      t.string :llm_model
      t.text   :llm_sustem_prompt

      t.timestamps
    end
  end
end

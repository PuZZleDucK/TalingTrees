# frozen_string_literal: true

# Migration to create the tree_relationships table.
class CreateTreeRelationships < ActiveRecord::Migration[7.1]
  def change
    create_table :tree_relationships do |t|
      t.integer :tree_id
      t.integer :related_tree_id
      t.string :kind

      t.timestamps
    end

    add_index :tree_relationships, %i[tree_id related_tree_id kind], unique: true,
                                                                     name: 'index_tree_relationships_unique'
    add_index :tree_relationships, :related_tree_id
  end
end

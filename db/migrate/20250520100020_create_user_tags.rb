# frozen_string_literal: true

# Migration to create the user_tags table.
class CreateUserTags < ActiveRecord::Migration[7.1]
  def change
    create_table :user_tags do |t|
      t.references :tree, foreign_key: true
      t.references :user, foreign_key: true
      t.string :tag
      t.timestamps
    end
    add_index :user_tags, %i[tree_id user_id tag], unique: true
  end
end

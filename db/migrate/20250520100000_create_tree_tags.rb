# frozen_string_literal: true

class CreateTreeTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tree_tags do |t|
      t.references :user, foreign_key: true
      t.references :tree, foreign_key: true
      t.string :tag
      t.timestamps
    end
    add_index :tree_tags, %i[user_id tree_id tag], unique: true
  end
end

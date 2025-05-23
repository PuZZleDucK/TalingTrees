# frozen_string_literal: true

# Migration to create the chats table.
class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.references :user, foreign_key: true
      t.references :tree, foreign_key: true
      t.timestamps
    end
  end
end

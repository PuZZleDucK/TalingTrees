# frozen_string_literal: true

# Migration to add a tag column to tree_relationships.
class AddTagToTreeRelationships < ActiveRecord::Migration[7.1]
  def change
    add_column :tree_relationships, :tag, :string
  end
end

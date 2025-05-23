# frozen_string_literal: true

class AddTagToTreeRelationships < ActiveRecord::Migration[7.1]
  def change
    add_column :tree_relationships, :tag, :string
  end
end

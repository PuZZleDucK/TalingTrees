class CreateUserTrees < ActiveRecord::Migration[7.1]
  def change
    create_table :user_trees do |t|
      t.references :user, foreign_key: true
      t.references :tree, foreign_key: true
      t.timestamps
    end

    add_index :user_trees, [:user_id, :tree_id], unique: true
  end
end

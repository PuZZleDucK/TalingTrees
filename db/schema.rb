# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_05_17_152630) do
  create_table "chats", force: :cascade do |t|
    t.integer "user_id"
    t.integer "tree_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tree_id"], name: "index_chats_on_tree_id"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "chat_id"
    t.string "role"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "tree_relationships", force: :cascade do |t|
    t.integer "tree_id"
    t.integer "related_tree_id"
    t.string "kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["related_tree_id"], name: "index_tree_relationships_on_related_tree_id"
    t.index ["tree_id", "related_tree_id", "kind"], name: "index_tree_relationships_unique", unique: true
  end

  create_table "user_trees", force: :cascade do |t|
    t.integer "user_id"
    t.integer "tree_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "tree_id"], name: "index_user_trees_on_user_id_and_tree_id", unique: true
    t.index ["tree_id"], name: "index_user_trees_on_tree_id"
    t.index ["user_id"], name: "index_user_trees_on_user_id"
  end

  create_table "trees", force: :cascade do |t|
    t.string "name"
    t.string "treedb_com_id"
    t.string "treedb_common_name"
    t.string "treedb_genus"
    t.string "treedb_family"
    t.string "treedb_diameter"
    t.date "treedb_date_planted"
    t.string "treedb_age_description"
    t.string "treedb_useful_life_expectency_value"
    t.string "treedb_precinct"
    t.string "treedb_located_in"
    t.date "treedb_uploaddate"
    t.float "treedb_lat"
    t.float "treedb_long"
    t.string "llm_model"
    t.text "llm_sustem_prompt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.text "blurb"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "lat"
    t.float "long"
  end

  add_foreign_key "chats", "trees"
  add_foreign_key "chats", "users"
  add_foreign_key "messages", "chats"
end

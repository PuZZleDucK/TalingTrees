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

ActiveRecord::Schema[7.2].define(version: 2025_09_27_140000) do
  create_table "ahoy_events", force: :cascade do |t|
    t.integer "visit_id"
    t.integer "user_id"
    t.string "name"
    t.text "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.integer "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.integer "user_id"
    t.integer "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.integer "creator_id"
    t.integer "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.integer "dashboard_id"
    t.integer "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.integer "creator_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.integer "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

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

  create_table "points_of_interest", force: :cascade do |t|
    t.string "site_name", null: false
    t.string "vhr_number"
    t.string "vhi_number"
    t.string "herit_obj"
    t.string "hermes_number"
    t.bigint "ufi"
    t.integer "external_id"
    t.datetime "ufi_created_at"
    t.float "centroid_lat"
    t.float "centroid_long"
    t.text "boundary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_name"], name: "index_points_of_interest_on_site_name"
    t.index ["ufi"], name: "index_points_of_interest_on_ufi", unique: true
    t.index ["vhr_number"], name: "index_points_of_interest_on_vhr_number"
  end

  create_table "suburbs", force: :cascade do |t|
    t.string "name"
    t.text "boundary"
    t.integer "tree_count", default: 0, null: false
  end

  create_table "tree_relationships", force: :cascade do |t|
    t.integer "tree_id"
    t.integer "related_tree_id"
    t.string "kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tag"
    t.index ["related_tree_id"], name: "index_tree_relationships_on_related_tree_id"
    t.index ["tree_id", "related_tree_id", "kind"], name: "index_tree_relationships_unique", unique: true
  end

  create_table "tree_tags", force: :cascade do |t|
    t.integer "user_id"
    t.integer "tree_id"
    t.string "tag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tree_id"], name: "index_tree_tags_on_tree_id"
    t.index ["user_id", "tree_id", "tag"], name: "index_tree_tags_on_user_id_and_tree_id_and_tag", unique: true
    t.index ["user_id"], name: "index_tree_tags_on_user_id"
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
    t.text "llm_system_prompt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_tags", force: :cascade do |t|
    t.integer "tree_id"
    t.integer "user_id"
    t.string "tag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tree_id", "user_id", "tag"], name: "index_user_tags_on_tree_id_and_user_id_and_tag", unique: true
    t.index ["tree_id"], name: "index_user_tags_on_tree_id"
    t.index ["user_id"], name: "index_user_tags_on_user_id"
  end

  create_table "user_trees", force: :cascade do |t|
    t.integer "user_id"
    t.integer "tree_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tree_id"], name: "index_user_trees_on_tree_id"
    t.index ["user_id"], name: "index_user_trees_on_user_id"
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
  add_foreign_key "tree_tags", "trees"
  add_foreign_key "tree_tags", "users"
  add_foreign_key "user_tags", "trees"
  add_foreign_key "user_tags", "users"
  add_foreign_key "user_trees", "trees"
  add_foreign_key "user_trees", "users"
end

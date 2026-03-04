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

ActiveRecord::Schema[8.1].define(version: 2026_03_04_153200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "children", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "grade"
    t.string "inbound_alias"
    t.string "name", null: false
    t.bigint "parent_id", null: false
    t.string "school_name"
    t.datetime "updated_at", null: false
    t.index ["inbound_alias"], name: "index_children_on_inbound_alias", unique: true
    t.index ["parent_id"], name: "index_children_on_parent_id"
  end

  create_table "communications", force: :cascade do |t|
    t.text "ai_error"
    t.jsonb "ai_extracted"
    t.jsonb "ai_raw_response"
    t.string "ai_status", default: "pending", null: false
    t.text "body_html"
    t.text "body_text"
    t.bigint "child_id", null: false
    t.datetime "created_at", null: false
    t.string "from_email"
    t.string "from_name"
    t.jsonb "raw_payload", default: {}, null: false
    t.datetime "received_at"
    t.string "source"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["ai_status"], name: "index_communications_on_ai_status"
    t.index ["child_id"], name: "index_communications_on_child_id"
    t.index ["raw_payload"], name: "index_communications_on_raw_payload", using: :gin
    t.index ["received_at"], name: "index_communications_on_received_at"
  end

  create_table "parents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_parents_on_email", unique: true
  end

  add_foreign_key "children", "parents"
  add_foreign_key "communications", "children"
end

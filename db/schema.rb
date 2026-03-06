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

ActiveRecord::Schema[8.1].define(version: 2026_03_06_230100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "artifacts", force: :cascade do |t|
    t.text "ai_error"
    t.jsonb "ai_raw_response", default: {}, null: false
    t.string "ai_status", default: "pending", null: false
    t.text "body_html"
    t.text "body_text"
    t.datetime "captured_at", null: false
    t.float "category_confidence"
    t.bigint "child_id", null: false
    t.bigint "communication_id", null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.jsonb "extracted_payload", default: {}, null: false
    t.string "from_email"
    t.string "from_name"
    t.jsonb "metadata", default: {}, null: false
    t.text "normalized_text"
    t.datetime "occurred_at"
    t.text "ocr_text"
    t.string "processing_state", default: "pending", null: false
    t.text "raw_extracted_text"
    t.jsonb "raw_payload", default: {}, null: false
    t.string "source"
    t.string "source_type", null: false
    t.string "subject"
    t.string "system_category"
    t.jsonb "tags", default: [], null: false
    t.string "text_extraction_method"
    t.float "text_quality_score"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "user_category"
    t.index ["ai_status"], name: "index_artifacts_on_ai_status"
    t.index ["captured_at"], name: "index_artifacts_on_captured_at"
    t.index ["child_id"], name: "index_artifacts_on_child_id"
    t.index ["communication_id"], name: "index_artifacts_on_communication_id"
    t.index ["content_type"], name: "index_artifacts_on_content_type"
    t.index ["extracted_payload"], name: "index_artifacts_on_extracted_payload", using: :gin
    t.index ["metadata"], name: "index_artifacts_on_metadata", using: :gin
    t.index ["occurred_at"], name: "index_artifacts_on_occurred_at"
    t.index ["processing_state"], name: "index_artifacts_on_processing_state"
    t.index ["source_type"], name: "index_artifacts_on_source_type"
    t.index ["system_category"], name: "index_artifacts_on_system_category"
    t.index ["tags"], name: "index_artifacts_on_tags", using: :gin
  end

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

  create_table "communication_contacts", force: :cascade do |t|
    t.bigint "communication_id", null: false
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["communication_id", "contact_id"], name: "idx_comm_contact_unique", unique: true
    t.index ["communication_id"], name: "index_communication_contacts_on_communication_id"
    t.index ["contact_id"], name: "index_communication_contacts_on_contact_id"
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

  create_table "contacts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "family_id", null: false
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["email"], name: "index_contacts_on_email"
    t.index ["family_id", "email"], name: "index_contacts_on_family_id_and_email", unique: true
    t.index ["family_id", "phone"], name: "index_contacts_on_family_id_and_phone", unique: true, where: "(phone IS NOT NULL)"
    t.index ["family_id"], name: "index_contacts_on_family_id"
    t.index ["user_id"], name: "index_contacts_on_user_id", unique: true
  end

  create_table "families", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "parents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.bigint "family_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_parents_on_email", unique: true
    t.index ["family_id"], name: "index_parents_on_family_id"
  end

  create_table "postmark_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "message_id"
    t.jsonb "payload", default: {}, null: false
    t.string "recipient"
    t.datetime "recorded_at"
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_postmark_events_on_event_type"
    t.index ["message_id"], name: "index_postmark_events_on_message_id"
    t.index ["recorded_at"], name: "index_postmark_events_on_recorded_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.bigint "invited_by_id"
    t.boolean "must_change_password", default: false, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "PARENT", null: false
    t.datetime "temporary_password_sent_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "artifacts", "children"
  add_foreign_key "artifacts", "communications"
  add_foreign_key "children", "parents"
  add_foreign_key "communication_contacts", "communications"
  add_foreign_key "communication_contacts", "contacts"
  add_foreign_key "communications", "children"
  add_foreign_key "contacts", "families"
  add_foreign_key "contacts", "users"
  add_foreign_key "parents", "families"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "users", "users", column: "invited_by_id"
end

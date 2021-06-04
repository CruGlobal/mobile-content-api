# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_06_03_152052) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "access_codes", id: :serial, force: :cascade do |t|
    t.string "code", null: false
    t.datetime "expiration", default: "2016-01-01 01:00:00", null: false
    t.index ["code"], name: "index_access_codes_on_code", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "attachments", id: :serial, force: :cascade do |t|
    t.string "file_file_name"
    t.string "file_content_type"
    t.string "file_file_size"
    t.string "file_updated_at"
    t.integer "resource_id"
    t.boolean "is_zipped", default: false, null: false
    t.string "sha256"
    t.string "filename"
    t.index ["resource_id"], name: "index_attachments_on_resource_id"
  end

  create_table "attributes", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.string "value", null: false
    t.boolean "is_translatable", default: false
    t.integer "resource_id", null: false
    t.index ["key", "resource_id"], name: "index_attributes_on_key_and_resource_id", unique: true
    t.index ["resource_id"], name: "index_attributes_on_resource_id"
  end

  create_table "auth_tokens", id: :serial, force: :cascade do |t|
    t.string "token", null: false
    t.integer "access_code_id", null: false
    t.datetime "expiration", default: "2016-01-01 01:00:00", null: false
    t.index ["access_code_id"], name: "index_auth_tokens_on_access_code_id"
    t.index ["token"], name: "index_auth_tokens_on_token", unique: true
  end

  create_table "custom_manifests", id: :serial, force: :cascade do |t|
    t.string "structure", null: false
    t.integer "resource_id", null: false
    t.integer "language_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["language_id"], name: "index_custom_manifests_on_language_id"
    t.index ["resource_id", "language_id"], name: "index_custom_manifests_on_resource_id_and_language_id", unique: true
    t.index ["resource_id"], name: "index_custom_manifests_on_resource_id"
  end

  create_table "custom_pages", id: :serial, force: :cascade do |t|
    t.string "structure", null: false
    t.integer "page_id", null: false
    t.integer "language_id", null: false
    t.index ["language_id"], name: "index_custom_pages_on_language_id"
    t.index ["page_id", "language_id"], name: "index_custom_pages_on_page_id_and_language_id", unique: true
    t.index ["page_id"], name: "index_custom_pages_on_page_id"
  end

  create_table "custom_tips", force: :cascade do |t|
    t.string "structure", null: false
    t.integer "tip_id", null: false
    t.integer "language_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["language_id"], name: "index_custom_tips_on_language_id"
    t.index ["tip_id", "language_id"], name: "index_custom_tips_on_tip_id_and_language_id", unique: true
    t.index ["tip_id"], name: "index_custom_tips_on_tip_id"
  end

  create_table "destinations", id: :serial, force: :cascade do |t|
    t.string "url", null: false
    t.string "route_id"
    t.string "access_key_id"
    t.string "access_key_secret"
    t.string "service_type", null: false
    t.string "service_name"
  end

  create_table "follow_ups", id: :serial, force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.integer "language_id", null: false
    t.integer "destination_id", null: false
    t.index ["destination_id"], name: "index_follow_ups_on_destination_id"
    t.index ["language_id"], name: "index_follow_ups_on_language_id"
  end

  create_table "global_activity_analytics", id: :integer, default: 1, force: :cascade do |t|
    t.integer "users", default: 0, null: false
    t.integer "countries", default: 0, null: false
    t.integer "launches", default: 0, null: false
    t.integer "gospel_presentations", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_global_activity_analytics_on_id", unique: true
  end

  create_table "language_attributes", force: :cascade do |t|
    t.integer "language_id", null: false
    t.bigint "resource_id", null: false
    t.string "key", null: false
    t.string "value", null: false
    t.boolean "is_translatable", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key", "resource_id", "language_id"], name: "index_language_attributes_unique", unique: true
    t.index ["resource_id"], name: "index_language_attributes_on_resource_id"
  end

  create_table "languages", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "direction", default: "ltr"
    t.index ["code"], name: "index_languages_on_code", unique: true
  end

  create_table "pages", id: :serial, force: :cascade do |t|
    t.string "filename", null: false
    t.string "structure", null: false
    t.integer "resource_id", null: false
    t.integer "position", null: false
    t.index ["position", "resource_id"], name: "index_pages_on_position_and_resource_id", unique: true
    t.index ["resource_id"], name: "index_pages_on_resource_id"
  end

  create_table "resource_types", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "dtd_file", null: false
    t.index ["name"], name: "index_resource_types_on_name", unique: true
  end

  create_table "resources", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation", null: false
    t.integer "onesky_project_id"
    t.integer "system_id", null: false
    t.string "description"
    t.integer "resource_type_id", null: false
    t.string "manifest"
    t.integer "total_views", default: 0, null: false
    t.index ["abbreviation"], name: "index_resources_on_abbreviation", unique: true
    t.index ["resource_type_id"], name: "index_resources_on_resource_type_id"
    t.index ["system_id"], name: "index_resources_on_system_id"
  end

  create_table "systems", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_systems_on_name", unique: true
  end

  create_table "tips", force: :cascade do |t|
    t.integer "resource_id"
    t.string "name"
    t.string "structure"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_id", "name"], name: "index_tips_on_resource_id_and_name", unique: true
  end

  create_table "translated_attributes", id: :serial, force: :cascade do |t|
    t.string "value", null: false
    t.integer "attribute_id", null: false
    t.integer "translation_id", null: false
    t.index ["attribute_id", "translation_id"], name: "index_translated_attributes_on_attribute_id_and_translation_id", unique: true
    t.index ["attribute_id"], name: "index_translated_attributes_on_attribute_id"
    t.index ["translation_id"], name: "index_translated_attributes_on_translation_id"
  end

  create_table "translated_pages", id: :serial, force: :cascade do |t|
    t.string "value", null: false
    t.integer "language_id", null: false
    t.integer "resource_id", null: false
    t.index ["language_id"], name: "index_translated_pages_on_language_id"
    t.index ["resource_id"], name: "index_translated_pages_on_resource_id"
  end

  create_table "translations", id: :serial, force: :cascade do |t|
    t.boolean "is_published", default: false
    t.integer "version", default: 1, null: false
    t.integer "resource_id", null: false
    t.integer "language_id", null: false
    t.string "translated_name"
    t.string "translated_description"
    t.string "manifest_name"
    t.string "translated_tagline"
    t.index ["language_id"], name: "index_translations_on_language_id"
    t.index ["resource_id", "language_id", "version"], name: "index_translations_on_resource_id_and_language_id_and_version", unique: true
    t.index ["resource_id"], name: "index_translations_on_resource_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attachments", "resources"
  add_foreign_key "attributes", "resources"
  add_foreign_key "auth_tokens", "access_codes"
  add_foreign_key "custom_manifests", "languages"
  add_foreign_key "custom_manifests", "resources"
  add_foreign_key "custom_pages", "languages"
  add_foreign_key "custom_pages", "pages"
  add_foreign_key "follow_ups", "destinations"
  add_foreign_key "follow_ups", "languages"
  add_foreign_key "pages", "resources"
  add_foreign_key "resources", "resource_types"
  add_foreign_key "resources", "systems"
  add_foreign_key "translated_attributes", "attributes"
  add_foreign_key "translated_attributes", "translations"
  add_foreign_key "translated_pages", "languages"
  add_foreign_key "translated_pages", "resources"
  add_foreign_key "translations", "languages"
  add_foreign_key "translations", "resources"
end

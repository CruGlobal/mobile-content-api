# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170601143623) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_codes", force: :cascade do |t|
    t.string   "code",                                       null: false
    t.datetime "expiration", default: '2016-01-01 01:00:00', null: false
    t.index ["code"], name: "index_access_codes_on_code", unique: true, using: :btree
  end

  create_table "attachments", force: :cascade do |t|
    t.string   "file_file_name",                    null: false
    t.string   "file_content_type",                 null: false
    t.integer  "file_file_size",                    null: false
    t.datetime "file_updated_at",                   null: false
    t.integer  "resource_id"
    t.boolean  "is_zipped",         default: false, null: false
    t.string   "sha256"
    t.index ["resource_id"], name: "index_attachments_on_resource_id", using: :btree
  end

  create_table "attributes", force: :cascade do |t|
    t.string  "key",                             null: false
    t.string  "value",                           null: false
    t.boolean "is_translatable", default: false
    t.integer "resource_id",                     null: false
    t.index ["key", "resource_id"], name: "index_attributes_on_key_and_resource_id", unique: true, using: :btree
    t.index ["resource_id"], name: "index_attributes_on_resource_id", using: :btree
  end

  create_table "auth_tokens", force: :cascade do |t|
    t.string   "token",                                          null: false
    t.integer  "access_code_id",                                 null: false
    t.datetime "expiration",     default: '2016-01-01 01:00:00', null: false
    t.index ["access_code_id"], name: "index_auth_tokens_on_access_code_id", using: :btree
    t.index ["token"], name: "index_auth_tokens_on_token", unique: true, using: :btree
  end

  create_table "custom_pages", force: :cascade do |t|
    t.string  "structure",      null: false
    t.integer "page_id",        null: false
    t.integer "translation_id", null: false
    t.index ["page_id", "translation_id"], name: "index_custom_pages_on_page_id_and_translation_id", unique: true, using: :btree
    t.index ["page_id"], name: "index_custom_pages_on_page_id", using: :btree
    t.index ["translation_id"], name: "index_custom_pages_on_translation_id", using: :btree
  end

  create_table "languages", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.index ["code"], name: "index_languages_on_code", unique: true, using: :btree
  end

  create_table "pages", force: :cascade do |t|
    t.string  "filename",    null: false
    t.string  "structure",   null: false
    t.integer "resource_id", null: false
    t.integer "position",    null: false
    t.index ["position", "resource_id"], name: "index_pages_on_position_and_resource_id", unique: true, using: :btree
    t.index ["resource_id"], name: "index_pages_on_resource_id", using: :btree
  end

  create_table "resource_types", force: :cascade do |t|
    t.string "name",     null: false
    t.string "dtd_file", null: false
    t.index ["name"], name: "index_resource_types_on_name", unique: true, using: :btree
  end

  create_table "resources", force: :cascade do |t|
    t.string  "name",              null: false
    t.string  "abbreviation",      null: false
    t.integer "onesky_project_id"
    t.integer "system_id",         null: false
    t.string  "description"
    t.string  "manifest"
    t.integer "resource_type_id",  null: false
    t.index ["abbreviation"], name: "index_resources_on_abbreviation", unique: true, using: :btree
    t.index ["resource_type_id"], name: "index_resources_on_resource_type_id", using: :btree
    t.index ["system_id"], name: "index_resources_on_system_id", using: :btree
  end

  create_table "systems", force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_systems_on_name", unique: true, using: :btree
  end

  create_table "translated_attributes", force: :cascade do |t|
    t.string  "value",          null: false
    t.integer "attribute_id",   null: false
    t.integer "translation_id", null: false
    t.index ["attribute_id", "translation_id"], name: "index_translated_attributes_on_attribute_id_and_translation_id", unique: true, using: :btree
    t.index ["attribute_id"], name: "index_translated_attributes_on_attribute_id", using: :btree
    t.index ["translation_id"], name: "index_translated_attributes_on_translation_id", using: :btree
  end

  create_table "translated_pages", force: :cascade do |t|
    t.string  "value",          null: false
    t.integer "page_id",        null: false
    t.integer "translation_id", null: false
    t.index ["page_id", "translation_id"], name: "index_translated_pages_on_page_id_and_translation_id", unique: true, using: :btree
    t.index ["page_id"], name: "index_translated_pages_on_page_id", using: :btree
    t.index ["translation_id"], name: "index_translated_pages_on_translation_id", using: :btree
  end

  create_table "translations", force: :cascade do |t|
    t.boolean "is_published",           default: false
    t.integer "version",                default: 1,     null: false
    t.integer "resource_id",                            null: false
    t.integer "language_id",                            null: false
    t.string  "translated_name"
    t.string  "translated_description"
    t.string  "manifest_name"
    t.index ["language_id"], name: "index_translations_on_language_id", using: :btree
    t.index ["resource_id"], name: "index_translations_on_resource_id", using: :btree
  end

  create_table "views", force: :cascade do |t|
    t.integer "quantity",    null: false
    t.integer "resource_id", null: false
    t.index ["resource_id"], name: "index_views_on_resource_id", using: :btree
  end

  add_foreign_key "attachments", "resources"
  add_foreign_key "attributes", "resources"
  add_foreign_key "auth_tokens", "access_codes"
  add_foreign_key "custom_pages", "pages"
  add_foreign_key "custom_pages", "translations"
  add_foreign_key "pages", "resources"
  add_foreign_key "resources", "resource_types"
  add_foreign_key "resources", "systems"
  add_foreign_key "translated_attributes", "attributes"
  add_foreign_key "translated_attributes", "translations"
  add_foreign_key "translations", "languages"
  add_foreign_key "translations", "resources"
  add_foreign_key "views", "resources"
end

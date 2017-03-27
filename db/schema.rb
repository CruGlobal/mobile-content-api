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

ActiveRecord::Schema.define(version: 20170324171408) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_codes", force: :cascade do |t|
    t.string "code"
  end

  create_table "auth_tokens", force: :cascade do |t|
    t.string  "token"
    t.integer "access_code_id", null: false
    t.index ["access_code_id"], name: "index_auth_tokens_on_access_code_id", using: :btree
  end

  create_table "languages", force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.index ["abbreviation"], name: "index_languages_on_abbreviation", unique: true, using: :btree
  end

  create_table "pages", force: :cascade do |t|
    t.string  "filename"
    t.string  "structure"
    t.integer "resource_id", null: false
    t.index ["resource_id"], name: "index_pages_on_resource_id", using: :btree
  end

  create_table "resources", force: :cascade do |t|
    t.string  "name"
    t.string  "abbreviation"
    t.integer "onesky_project_id"
    t.integer "system_id",         null: false
    t.index ["abbreviation"], name: "index_resources_on_abbreviation", unique: true, using: :btree
    t.index ["system_id"], name: "index_resources_on_system_id", using: :btree
  end

  create_table "systems", force: :cascade do |t|
    t.string "name"
    t.index ["name"], name: "index_systems_on_name", unique: true, using: :btree
  end

  create_table "translation_elements", force: :cascade do |t|
    t.integer "page_order"
    t.string  "text"
    t.integer "page_id",    null: false
    t.index ["page_id"], name: "index_translation_elements_on_page_id", using: :btree
  end

  create_table "translations", force: :cascade do |t|
    t.boolean "is_published", default: false
    t.integer "version",      default: 1
    t.integer "resource_id",                  null: false
    t.integer "language_id",                  null: false
    t.index ["language_id"], name: "index_translations_on_language_id", using: :btree
    t.index ["resource_id"], name: "index_translations_on_resource_id", using: :btree
  end

end

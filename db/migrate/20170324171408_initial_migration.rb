# frozen_string_literal: true

class InitialMigration < ActiveRecord::Migration[5.0]
  def change
    create_table :systems do |t|
      t.string :name, index: {unique: true}, null: false
    end

    create_table :resources do |t|
      t.string :name, null: false
      t.string :abbreviation, index: {unique: true}, null: false
      t.integer :onesky_project_id, null: false
      t.references :system, null: false
    end

    create_table :languages do |t|
      t.string :name, null: false
      t.string :abbreviation, index: {unique: true}, null: false
    end

    create_table :translations do |t|
      t.boolean :is_published, default: false
      t.integer :version, default: 1, null: false
      t.references :resource, null: false
      t.references :language, null: false
    end

    create_table :access_codes do |t|
      t.string :code, null: false
    end

    create_table :auth_tokens do |t|
      t.string :token, null: false
      t.references :access_code, null: false
    end

    create_table :pages do |t|
      t.string :filename, null: false
      t.string :structure, null: false
      t.references :resource, null: false
    end

    create_table :custom_pages do |t|
      t.string :structure, null: false
      t.references :page, null: false
      t.references :translation, null: false
    end

    add_index :custom_pages, [:page_id, :translation_id], unique: true

    create_table :translation_elements do |t|
      t.integer :page_order
      t.string :text, null: false
      t.references :page, null: false
    end
  end
end

class InitialMigration < ActiveRecord::Migration[5.0]
  def change
    create_table :systems do |t|
      t.string :name, index: { unique: true }
    end

    create_table :resources do |t|
      t.string :name
      t.string :abbreviation, index: { unique: true }
      t.integer :onesky_project_id
      t.references :system, null: false
    end

    create_table :languages do |t|
      t.string :name
      t.string :abbreviation, index: { unique: true }
    end

    create_table :translations do |t|
      t.boolean :is_published, default: false
      t.integer :version, default: 1
      t.references :resource, null: false
      t.references :language, null: false
    end

    create_table :access_codes do |t|
      t.string :code
    end

    create_table :auth_tokens do |t|
      t.string :token
      t.references :access_code, null: false
    end

    create_table :pages do |t|
      t.string :filename
      t.string :structure
      t.references :resource, null: false
    end

    create_table :translation_pages do |t|
      t.string :structure
      t.references :page, null: false
      t.references :translation, null: false
    end

    create_table :translation_elements do |t|
      t.integer :page_order
      t.string :text
      t.references :page, null: false
    end

  end
end

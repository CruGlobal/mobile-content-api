class TranslatedPages < ActiveRecord::Migration[5.0]
  def change
    create_table :translated_pages do |t|
      t.string :value, null: false
      t.references :page, null: false
      t.references :translation, null: false
    end

    add_index :translated_pages, [:page_id, :translation_id], unique: true
  end
end

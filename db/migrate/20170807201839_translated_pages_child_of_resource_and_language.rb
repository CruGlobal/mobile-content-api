class TranslatedPagesChildOfResourceAndLanguage < ActiveRecord::Migration[5.0]
  def change
    add_reference :translated_pages, :language, index: true, null: false
    add_foreign_key :translated_pages, :languages

    add_reference :translated_pages, :resource, index: true, null: false
    add_foreign_key :translated_pages, :resources

    remove_column :translated_pages, :page_id, :integer
    remove_column :translated_pages, :translation_id, :integer
  end
end

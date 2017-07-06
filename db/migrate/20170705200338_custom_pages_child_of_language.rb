class CustomPagesChildOfLanguage < ActiveRecord::Migration[5.0]
  def change
    remove_column :custom_pages, :translation_id, :integer
    add_reference :custom_pages, :language, index: true, null: true
    add_foreign_key :custom_pages, :languages
    add_index :custom_pages, [:page_id, :language_id], unique: true
  end
end

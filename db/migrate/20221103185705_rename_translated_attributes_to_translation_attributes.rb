class RenameTranslatedAttributesToTranslationAttributes < ActiveRecord::Migration[6.1]
  def change
    rename_table :translated_attributes, :translation_attributes
  end
end

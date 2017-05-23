class RenameTranslationElementToOneskyPhrase < ActiveRecord::Migration[5.0]
  def change
    rename_table :translation_elements, :onesky_phrases
    rename_column :onesky_phrases, :onesky_phrase_id, :onesky_id
  end
end

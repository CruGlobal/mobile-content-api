class RenameOneskyPhraseIdToCrowdinPhraseIdInTranslatedAttributes < ActiveRecord::Migration[7.0]
  def change
    rename_column :translated_attributes, :onesky_phrase_id, :crowdin_phrase_id
  end
end

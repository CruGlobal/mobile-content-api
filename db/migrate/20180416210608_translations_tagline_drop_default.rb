class TranslationsTaglineDropDefault < ActiveRecord::Migration[5.0]
  def change
    change_column_default(:translations, :translated_tagline, nil)
    Translation.where(translated_tagline: "").update_all(translated_tagline: nil)
  end
end

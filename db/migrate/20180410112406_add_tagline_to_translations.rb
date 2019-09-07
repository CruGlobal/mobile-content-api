class AddTaglineToTranslations < ActiveRecord::Migration[5.0]
  def change
    add_column :translations, :translated_tagline, :string, default: ""
  end
end

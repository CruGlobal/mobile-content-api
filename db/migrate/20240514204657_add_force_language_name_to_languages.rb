class AddForceLanguageNameToLanguages < ActiveRecord::Migration[7.0]
  def change
    add_column :languages, :force_language_name, :boolean, default: false
  end
end

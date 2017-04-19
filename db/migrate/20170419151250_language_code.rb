class LanguageCode < ActiveRecord::Migration[5.0]
  def change
    rename_column :languages, :abbreviation, :code
  end
end

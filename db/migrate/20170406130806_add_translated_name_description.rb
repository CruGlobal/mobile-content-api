class AddTranslatedNameDescription < ActiveRecord::Migration[5.0]
  def change
    add_column :resources, :description, :string
    add_column :translations, :translated_name, :string
    add_column :translations, :translated_description, :string
  end
end

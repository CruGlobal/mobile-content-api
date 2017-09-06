class IndexLanguageResourceVersion < ActiveRecord::Migration[5.0]
  def change
    add_index :translations, [:resource_id, :language_id, :version], unique: true
  end
end

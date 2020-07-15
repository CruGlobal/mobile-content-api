class AddLanguageIdToAttributes < ActiveRecord::Migration[5.2]
  def change
    add_column :attributes, :language_id, :integer, null: true, default: nil
    #add_index :attributes, [:resource_id, :language_id, :key]
  end
end

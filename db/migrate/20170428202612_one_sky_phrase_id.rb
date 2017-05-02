class OneSkyPhraseId < ActiveRecord::Migration[5.0]
  def change
    add_column :translation_elements, :onesky_phrase_id, :string, null: false
    add_index :translation_elements, [:onesky_phrase_id], unique: true
  end
end

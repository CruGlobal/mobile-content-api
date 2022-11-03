class CreateTranslatedAttributes < ActiveRecord::Migration[6.1]
  def change
    create_table :translated_attributes do |t|
      t.integer :resource_id
      t.string :key
      t.string :onesky_phrase_id
      t.boolean :required

      t.timestamps
    end
  end
end

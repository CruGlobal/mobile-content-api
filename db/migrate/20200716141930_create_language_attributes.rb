class CreateLanguageAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :language_attributes do |t|
      t.integer :language_id, null: false
      t.integer :resource_id, null: false
      t.string :key, null: false
      t.string :value, null: false
      t.boolean :is_translatable, default: false
      t.references :resource, null: false

      t.timestamps
    end

    add_index :language_attributes, [:key, :resource_id, :language_id], unique: true, name: "index_language_attributes_unique"
  end
end

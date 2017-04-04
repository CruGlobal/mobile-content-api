class AddAttributes < ActiveRecord::Migration[5.0]
  def change
    create_table :attributes do |t|
      t.string :key, null: false
      t.string :value, null: false
      t.boolean :is_translatable, default: false
      t.references :resource, null: false
    end

    add_index :attributes, [:key, :resource_id], unique: true

    create_table :translated_attributes do |t|
      t.string :value, null: false
      t.references :attribute, null: false
      t.references :translation, null: false
    end

    add_index :translated_attributes, [:attribute_id, :translation_id], unique: true
  end
end

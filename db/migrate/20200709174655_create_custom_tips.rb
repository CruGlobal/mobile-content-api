class CreateCustomTips < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_tips do |t|
      t.string :structure, null: false
      t.integer :tip_id, null: false
      t.integer :language_id, null: false

      t.timestamps
    end

    add_index :custom_tips, :tip_id
    add_index :custom_tips, :language_id
    add_index :custom_tips, [:tip_id, :language_id], unique: true
  end
end

class SharingData < ActiveRecord::Migration[5.0]
  def change
    create_table :stats do |t|
      t.integer :quantity, null: false
      t.references :resource, null: false
    end
  end
end

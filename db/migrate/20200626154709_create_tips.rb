class CreateTips < ActiveRecord::Migration[5.2]
  def change
    create_table :tips do |t|
      t.integer :resource_id
      t.string :name
      t.string :structure

      t.timestamps
    end
  end
end

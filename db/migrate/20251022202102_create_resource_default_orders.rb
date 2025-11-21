class CreateResourceDefaultOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :resource_default_orders do |t|
      t.integer :position
      t.integer :resource_id
      t.string :lang

      t.timestamps
    end
    add_index :resource_default_orders, :resource_id
    add_index :resource_default_orders, :lang
  end
end

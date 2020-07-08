class AddKeyOnResourceAndTip < ActiveRecord::Migration[5.2]
  def change
    add_index :tips, [:resource_id, :name], unique: true
  end
end

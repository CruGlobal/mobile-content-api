class DropViewsTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :views
  end
end

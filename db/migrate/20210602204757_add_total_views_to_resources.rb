class AddTotalViewsToResources < ActiveRecord::Migration[6.0]
  def change
    add_column :resources, :total_views, :integer
  end
end

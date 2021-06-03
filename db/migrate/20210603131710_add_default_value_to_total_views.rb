class AddDefaultValueToTotalViews < ActiveRecord::Migration[6.0]
  def up
    change_column :resources, :total_views, :integer, null: false, default: 0
  end

  def down
    change_column :resources, :total_views, :integer, null: true, default: nil
  end
end

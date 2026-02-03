class AddDefaultOrderToResourceScore < ActiveRecord::Migration[7.1]
  def change
    add_column :resource_scores, :default_order, :integer
  end
end

class RemoveDefaultOrderFromResourceScore < ActiveRecord::Migration[7.1]
  def change
    remove_column :resource_scores, :default_order, :string
  end
end

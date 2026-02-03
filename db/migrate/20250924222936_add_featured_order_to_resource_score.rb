class AddFeaturedOrderToResourceScore < ActiveRecord::Migration[7.0]
  def change
    add_column :resource_scores, :featured_order, :integer
  end
end

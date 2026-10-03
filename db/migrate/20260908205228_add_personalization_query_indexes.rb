class AddPersonalizationQueryIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :resource_scores, [:language_id, :country]
    add_index :resource_default_orders, :language_id
  end
end

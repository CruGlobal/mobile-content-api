class AddDefaultVariantIdToResources < ActiveRecord::Migration[6.1]
  def change
    add_reference :resources, :default_variant, foreign_key: {to_table: :resources}
  end
end

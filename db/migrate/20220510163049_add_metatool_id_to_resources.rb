class AddMetatoolIdToResources < ActiveRecord::Migration[6.1]
  def change
    add_reference :resources, :metatool, foreign_key: {to_table: :resources}
  end
end

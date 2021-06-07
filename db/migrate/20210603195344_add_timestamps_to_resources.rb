class AddTimestampsToResources < ActiveRecord::Migration[6.0]
  def change
    # these have to be nullable since there are existing records
    add_column :resources, :created_at, :datetime
    add_column :resources, :updated_at, :datetime
  end
end

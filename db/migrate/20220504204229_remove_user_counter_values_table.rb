class RemoveUserCounterValuesTable < ActiveRecord::Migration[6.1]
  def change
    return unless ActiveRecord::Base.connection.table_exists?("user_counter_values")
    drop_table :user_counter_values
  end
end

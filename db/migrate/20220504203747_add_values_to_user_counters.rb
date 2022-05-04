class AddValuesToUserCounters < ActiveRecord::Migration[6.1]
  def change
    change_table :user_counters do |t|
      t.string 'values', array: true, default: "{}"
    end
    add_index :user_counters, :values, using: 'gin'
  end
end

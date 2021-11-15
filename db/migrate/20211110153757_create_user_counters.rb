class CreateUserCounters < ActiveRecord::Migration[6.0]
  def change
    create_table :user_counters do |t|
      t.integer :user_id
      t.string :counter_name
      t.integer :count, default: 0
      t.float :decayed_count
      t.date :last_decay

      t.timestamps
    end
  end
end

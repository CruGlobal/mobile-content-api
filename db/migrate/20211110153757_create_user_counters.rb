class CreateUserCounters < ActiveRecord::Migration[6.0]
  def change
    create_table :user_counters do |t|
      t.integer :user_id
      t.string :counter_name
      t.integer :count, default: 0
      t.float :decayed_count, default: 0
      t.date :last_decay, default: -> { timezone("utc", NOW()) }

      t.timestamps
    end
    add_index :user_counters, [:user_id, :counter_name], unique: true
  end
end

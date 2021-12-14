class CreateUserCounterValues < ActiveRecord::Migration[6.0]
  def change
    create_table :user_counter_values do |t|
      t.integer :user_id
      t.integer :user_counter_id
      t.string :value

      t.timestamps
    end
  end
end

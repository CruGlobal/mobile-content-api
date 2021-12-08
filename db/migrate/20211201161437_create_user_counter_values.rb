class CreateUserCounterValues < ActiveRecord::Migration[6.0]
  def change
    create_table :user_counter_values do |t|
      t.string :user_id
      t.string :user_counter_id
      t.string :value

      t.timestamps
    end
  end
end

class AddGlobalActivityAnalytics < ActiveRecord::Migration[5.2]
  def change
    create_table :global_activity_analytics, id: false do |t|
      t.integer :id, null: false, primary_key: true, default: 1, index: {unique: true}
      t.integer :users, null: false, default: 0
      t.integer :countries, null: false, default: 0
      t.integer :launches, null: false, default: 0
      t.integer :gospel_presentations, null: false, default: 0
      t.timestamp :updated_at, null: false
    end
  end
end

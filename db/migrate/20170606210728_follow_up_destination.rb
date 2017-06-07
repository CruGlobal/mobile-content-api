class FollowUpDestination < ActiveRecord::Migration[5.0]
  def change
    create_table :destinations do |t|
      t.string :url, null: false
      t.string :route_id, null: true
      t.string :access_key_id, null: true
      t.string :access_key_secret, null: true
    end
  end
end

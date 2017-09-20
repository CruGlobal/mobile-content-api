class StoreFollowUps < ActiveRecord::Migration[5.0]
  def change
    create_table :follow_ups do |t|
      t.string :email, null: false
      t.string :name, null: true
      t.references :language, null: false
      t.references :destination, null: false
    end

    add_foreign_key :follow_ups, :languages
    add_foreign_key :follow_ups, :destinations
  end
end

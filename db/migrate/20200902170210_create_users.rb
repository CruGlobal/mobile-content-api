class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    enable_extension "citext"

    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.citext :email
      t.string :okta_id

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :okta_id, unique: true
  end
end

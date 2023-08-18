class CreateUserAttributes < ActiveRecord::Migration[6.1]
  def change
    create_table :user_attributes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key
      t.string :value

      t.timestamps
    end
  end
end

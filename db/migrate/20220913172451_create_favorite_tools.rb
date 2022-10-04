class CreateFavoriteTools < ActiveRecord::Migration[6.1]
  def change
    create_table :favorite_tools do |t|
      t.integer :tool_id
      t.integer :user_id

      t.timestamps
    end
  end
end

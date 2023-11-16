class CreateUserTrainingTip < ActiveRecord::Migration[6.1]
  def change
    create_table :user_training_tips do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tool, null: false, foreign_key: {to_table: :resources}
      t.references :language, null: false, foreign_key: true
      t.string :tip_id
      t.boolean :is_completed

      t.timestamps
    end

    add_index :user_training_tips, [:user_id, :tool_id, :language_id, :tip_id], unique: true, name: "training-tips-unique-index"
  end
end

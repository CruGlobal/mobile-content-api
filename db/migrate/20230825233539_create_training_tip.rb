class CreateTrainingTip < ActiveRecord::Migration[6.1]
  def change
    create_table :training_tips do |t|
      t.string :tool
      t.string :locale
      t.references :tip, null: false, foreign_key: true
      t.boolean :is_completed

      t.timestamps
    end
  end
end

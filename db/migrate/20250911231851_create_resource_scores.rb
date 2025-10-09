class CreateResourceScores < ActiveRecord::Migration[7.0]
  def change
    create_table :resource_scores do |t|
      t.integer :resource_id
      t.boolean :featured
      t.string :country
      t.string :lang
      t.integer :score
      t.float :user_score_average
      t.integer :user_score_count

      t.timestamps
    end
    add_index :resource_scores, :resource_id
    add_index :resource_scores, [:lang, :country]
  end
end

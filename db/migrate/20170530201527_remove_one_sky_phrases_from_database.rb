class RemoveOneSkyPhrasesFromDatabase < ActiveRecord::Migration[5.0]
  def change
    drop_table :onesky_phrases do |t|
      t.string :text, null: false
      t.string :onesky_id, index: {unique: true}, null: false
      t.references :page, null: false
    end
  end
end

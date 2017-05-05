class AddFiles < ActiveRecord::Migration[5.0]
  def change
    create_table :attachments do |t|
      t.string :key, null: false
      t.attachment :file, null: false
      t.references :resource
      t.references :translation
    end
  end
end

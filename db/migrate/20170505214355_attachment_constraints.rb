class AttachmentConstraints < ActiveRecord::Migration[5.0]
  def change
    add_index :attachments, [:key, :resource_id], unique: true
    add_index :attachments, [:key, :translation_id], unique: true
  end
end

class RemoveAttachmentFields < ActiveRecord::Migration[5.0]
  def change
    remove_column :attachments, :key, :string
    remove_column :attachments, :translation_id, :integer
  end
end

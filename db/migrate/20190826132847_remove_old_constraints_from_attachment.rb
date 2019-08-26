class RemoveOldConstraintsFromAttachment < ActiveRecord::Migration[5.2]
  def change
    change_column :attachments, :file_file_name, :string, null: true
    change_column :attachments, :file_content_type, :string, null: true
    change_column :attachments, :file_file_size, :string, null: true
    change_column :attachments, :file_updated_at, :string, null: true
  end
end

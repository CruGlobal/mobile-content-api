class StoreAttachmentSha < ActiveRecord::Migration[5.0]
  def change
    add_column :attachments, :sha256, :string
  end
end

class AddFilenameToAttachment < ActiveRecord::Migration[5.2]
  def change
    add_column :attachments, :filename, :string
  end
end

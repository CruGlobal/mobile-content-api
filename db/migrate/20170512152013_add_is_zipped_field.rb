class AddIsZippedField < ActiveRecord::Migration[5.0]
  def change
    add_column :attachments, :is_zipped, :boolean, null: false, default: false
  end
end

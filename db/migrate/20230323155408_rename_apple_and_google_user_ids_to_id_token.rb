class RenameAppleAndGoogleUserIdsToIdToken < ActiveRecord::Migration[6.1]
  def change
    rename_column :users, :google_user_id, :google_id_token
    rename_column :users, :apple_user_id, :apple_id_token
  end
end

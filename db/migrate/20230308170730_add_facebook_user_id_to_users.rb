class AddFacebookUserIdToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :facebook_user_id, :string
  end
end

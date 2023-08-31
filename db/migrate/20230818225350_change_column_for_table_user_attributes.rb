class ChangeColumnForTableUserAttributes < ActiveRecord::Migration[6.1]
  def change
    change_column :user_attributes, :user_id, :integer
  end
end

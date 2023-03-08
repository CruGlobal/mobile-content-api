class AddShortNameToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :short_name, :string
  end
end

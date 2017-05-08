class ExpireCodesAndTokens < ActiveRecord::Migration[5.0]
  def change
    add_column :access_codes, :expiration, :datetime, null: false
    add_column :auth_tokens, :expiration, :datetime, null: false
  end
end

class ExpireCodesAndTokens < ActiveRecord::Migration[5.0]
  def change
    add_column :access_codes, :expiration, :datetime, null: false, default: '2016-01-01T01:00:00.120Z'
    add_column :auth_tokens, :expiration, :datetime, null: false, default: '2016-01-01T01:00:00.120Z'
  end
end

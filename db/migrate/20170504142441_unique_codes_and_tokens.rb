class UniqueCodesAndTokens < ActiveRecord::Migration[5.0]
  def change
    add_index :access_codes, :code, unique: true
    add_index :auth_tokens, :token, unique: true
  end
end

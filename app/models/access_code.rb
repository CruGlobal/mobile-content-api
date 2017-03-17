class AccessCode < ActiveRecord::Base

  has_many :auth_tokens

end
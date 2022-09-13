class User < ApplicationRecord
  has_many :user_counters
  has_many :favorite_tools

  validates :sso_guid, uniqueness: true, presence: true

  # while the email needs to be validated case-insensitively, we'll
  # let Rails pass the insensitive check down to postgres's citext type
  validates :email, uniqueness: {case_sensitive: true}, presence: true
end

class User < ApplicationRecord
  has_many :user_counters, dependent: :destroy
  has_many :favorite_tools, dependent: :destroy
  has_many :tools, through: :favorite_tools

  validates :sso_guid, uniqueness: true, presence: true, unless: -> { facebook_user_id.present? || google_id_token.present? || apple_id_token.present? }

  # while the email needs to be validated case-insensitively, we'll
  # let Rails pass the insensitive check down to postgres's citext type
  validates :email, uniqueness: {case_sensitive: true}, presence: true
end

class User < ApplicationRecord
  has_many :user_counters, dependent: :destroy
  has_many :favorite_tools, dependent: :destroy
  has_many :tools, through: :favorite_tools
  has_many :training_tips

  validates :sso_guid, uniqueness: true, presence: true, unless: -> { facebook_user_id.present? || google_user_id.present? || apple_user_id.present? }
  validates :email, presence: true
end

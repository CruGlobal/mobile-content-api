class User < ApplicationRecord
  attr_accessor :create_user

  has_many :user_counters, dependent: :destroy
  has_many :favorite_tools, dependent: :destroy
  has_many :tools, through: :favorite_tools

  validates :sso_guid, uniqueness: true, presence: true, unless: -> { facebook_user_id.present? || google_user_id.present? || apple_user_id.present? }
  validates :email, presence: true
end

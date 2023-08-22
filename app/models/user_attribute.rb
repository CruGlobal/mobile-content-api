class UserAttribute < ApplicationRecord
  belongs_to :user

  validates :key, presence: true, format: {with: /\A[[:alpha:]]+(_[[:alpha:]]+)*\z/}, uniqueness: {scope: :user}
  validates :value, presence: true

  before_validation { self.key = key&.downcase }
end

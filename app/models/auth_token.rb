# frozen_string_literal: true

class AuthToken < ActiveRecord::Base
  belongs_to :access_code

  validates :access_code, presence: true
  validates :token, presence: true, uniqueness: true
  validates :expiration, presence: true

  before_validation { self.token = SecureRandom.uuid }
  before_validation :set_expiration, on: :create

  private

  def set_expiration
    self.expiration = DateTime.now.utc + 24.hours
  end
end

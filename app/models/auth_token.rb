# frozen_string_literal: true

class AuthToken < ActiveRecord::Base
  belongs_to :access_code

  validates :access_code, presence: true
  validates :token, presence: true

  before_validation :generate_token!

  private

  def generate_token!
    self.token = SecureRandom.uuid
  end
end

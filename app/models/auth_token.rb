# frozen_string_literal: true

class AuthToken < ActiveRecord::Base
  belongs_to :access_code

  validates :access_code, presence: true
  validates :token, presence: true

  before_validation :generate_token!

  def self.create_from_access_code!(access_code)
    create!(access_code: access_code)
    return :created
  rescue
    return :bad_request
  end

  private

  def generate_token!
    self.token = SecureRandom.uuid
  end
end

# frozen_string_literal: true

class AccessCode < ActiveRecord::Base
  class FailedAuthentication < StandardError
  end

  validates :code, presence: true, uniqueness: true
  validates :expiration, presence: true

  before_validation :set_expiration, on: :create

  def self.validate(code)
    code = AccessCode.find_by(code: code)

    raise AccessCode::FailedAuthentication, "Access code not found." if code.nil?
    raise AccessCode::FailedAuthentication, "Access code expired." if expired(code)

    code
  end

  def self.expired(code)
    code.expiration < DateTime.now.utc
  end

  private

  def set_expiration
    self.expiration = DateTime.now.utc + 7.days
  end
end

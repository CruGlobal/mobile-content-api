# frozen_string_literal: true

class AccessCode < ActiveRecord::Base
  validates :code, presence: true, uniqueness: true
  validates :expiration, presence: true

  before_validation :set_expiration, on: :create

  private

  def set_expiration
    self.expiration = DateTime.now.utc + 7.days
  end
end

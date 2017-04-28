# frozen_string_literal: true

class Attribute < ActiveRecord::Base
  belongs_to :resource

  has_many :translated_attributes

  validates :key, format: { with: /\A[[:alpha:]]+(_[[:alpha:]]+)*\z/ }

  before_validation :key_to_lower

  private

  def key_to_lower
    self.key = key.downcase if key.present?
  end
end

# frozen_string_literal: true

class Attribute < ActiveRecord::Base
  belongs_to :resource

  has_many :translated_attributes

  validates :key, presence: true, format: {with: /\A[[:alpha:]]+(_[[:alpha:]]+)*\z/}
  validates :value, presence: true
  validates :resource, presence: true, uniqueness: {scope: :key}
  validates :is_translatable, inclusion: {in: [true, false]}

  before_validation { self.key = key&.downcase }
  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.is_translatable ||= false
  end
end

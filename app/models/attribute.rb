# frozen_string_literal: true

class Attribute < ActiveRecord::Base
  belongs_to :resource

  has_many :translated_attributes

  validates :key, presence: true, format: { with: /\A[[:alpha:]]+(_[[:alpha:]]+)*\z/ }
  validates :value, presence: true
  validates :resource, presence: true, uniqueness: { scope: :key }
  validates :is_translatable, inclusion: { in: [true, false] }

  before_validation :key_to_lower
  before_validation :set_defaults, on: :create
  after_validation :duplicate_keys

  private

  def key_to_lower
    self.key = key.downcase if key.present?
  end

  def set_defaults
    self.is_translatable ||= false
  end

  def duplicate_keys
    return unless Attachment.find_by(resource_id: resource_id, key: key).present?
    raise 'Key is current used by an Attachment.'
  end
end

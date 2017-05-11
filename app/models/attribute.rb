# frozen_string_literal: true

require 'key_util'

class Attribute < ActiveRecord::Base
  belongs_to :resource

  has_many :translated_attributes

  validates :key, presence: true, format: { with: KeyUtil.format }
  validates :value, presence: true
  validates :resource, presence: true, uniqueness: { scope: :key }
  validates :is_translatable, inclusion: { in: [true, false] }

  before_validation -> { KeyUtil.lower_key(self) }
  before_validation :set_defaults, on: :create
  after_validation :duplicate_keys

  private

  def set_defaults
    self.is_translatable ||= false
  end

  def duplicate_keys # see note on same method in attachment.rb
    return unless resource.attachments.find_by(key: key).present?
    raise 'Key is current used by an Attachment.'
  end
end

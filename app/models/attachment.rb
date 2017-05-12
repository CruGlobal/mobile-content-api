# frozen_string_literal: true

require 'key_util'

class Attachment < ActiveRecord::Base
  validates :key, presence: true, format: { with: KeyUtil.format }
  validates :file, presence: true
  validates :resource, presence: true, uniqueness: { scope: :key }

  belongs_to :resource

  has_attached_file :file
  validates_attachment :file, content_type: { content_type: %w(image/jpg image/jpeg image/png image/gif) }

  before_validation -> { KeyUtil.lower_key(self) }
  after_validation :duplicate_keys

  private

  def duplicate_keys # TODO: would be nice to enforce this in the DB
    return unless resource.present? && resource.resource_attributes.find_by(resource_id: resource_id, key: key).present?
    raise 'Key is currently used by an Attribute.'
  end
end

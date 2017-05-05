# frozen_string_literal: true

class Attachment < ActiveRecord::Base
  validates :key, presence: true, format: { with: /\A[[:alpha:]]+(_[[:alpha:]]+)*\z/ }
  validates :file, presence: true
  validates :resource, uniqueness: { scope: :key }
  validates :translation, uniqueness: { scope: :key }

  belongs_to :resource, optional: true
  belongs_to :translation, optional: true

  has_attached_file :file
  validates_attachment :file, content_type: { content_type: %w(image/jpg image/jpeg image/png image/gif) }

  before_validation :key_to_lower, :resource_or_translation
  after_validation :duplicate_keys

  private

  def key_to_lower
    self.key = key.downcase if key.present?
  end

  def resource_or_translation
    raise 'Attachment must be related to Resource or Translation.' if resource_id.nil? && translation_id.nil?

    return unless resource_id.present? && translation_id.present?
    raise 'Attachment can be related to Resource OR Translation, not both.'
  end

  def duplicate_keys
    return unless Attribute.find_by(resource_id: resource_id, key: key).present?
    raise 'Key is currently used by an Attribute.'
  end
end

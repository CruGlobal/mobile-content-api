# frozen_string_literal: true

require 'xml_util'

class Attachment < ActiveRecord::Base
  validates :file, presence: true
  validates :is_zipped, inclusion: { in: [true, false] }
  validates :resource, presence: true, uniqueness: { scope: :file_file_name }
  validates_with AttachmentValidator

  belongs_to :resource

  has_attached_file :file
  validates_attachment :file, content_type: { content_type: %w(image/jpg image/jpeg image/png image/gif) }

  before_validation :set_defaults
  before_save :save_sha256

  def filename_sha
    queued = file.queued_for_write[:original]
    return unless queued

    XmlUtil.filename_sha(open(queued.path).read)
  end

  private

  def set_defaults
    self.is_zipped ||= false
  end

  def save_sha256
    self.sha256 = filename_sha
  end
end

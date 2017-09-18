# frozen_string_literal: true

require 'xml_util'

class Attachment < ActiveRecord::Base
  validates :file, presence: true
  validates :is_zipped, inclusion: { in: [true, false] }
  validates :resource, presence: true, uniqueness: { scope: :file_file_name }
  validates_with AttachmentValidator, if: :queued?

  belongs_to :resource

  has_attached_file :file
  validates_attachment :file, content_type: { content_type: %w(image/jpg image/jpeg image/png image/gif) }

  before_validation :set_defaults
  before_save :save_sha256, if: :queued?

  def queued?
    file.queued_for_write[:original]
  end

  private

  def set_defaults
    self.is_zipped ||= false
  end

  def save_sha256
    self.sha256 = XmlUtil.filename_sha(open(file.queued_for_write[:original].path).read)
  end
end

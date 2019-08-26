# frozen_string_literal: true

require 'xml_util'

class Attachment < ActiveRecord::Base
  validates :file, attached: true
  validates :is_zipped, inclusion: { in: [true, false] }
  validates :resource, presence: true
  validates_with AttachmentValidator, if: :queued

  belongs_to :resource

  has_one_attached :file
  validates :file, file_content_type: {
    allow: ['image/jpeg', 'image/png', 'image/gif', 'image/jpg'],
    if: -> { file.attached? }
  }

  before_validation :set_defaults
  before_save :save_sha256, if: :queued

  def queued
    file.attached?
  end

  def generate_sha256
    return XmlUtil.filename_sha(open(ActiveStorage::Blob.service.send(:path_for, file.key)).read) if Rails.env == "test"
    XmlUtil.filename_sha(open(Rails.application.routes.url_helpers.rails_blob_path(file)).read)
  end

  private

  def attached_filename
    file.filename.to_s
  end

  def set_defaults
    self.is_zipped ||= false
  end

  def save_sha256
    self.sha256 = generate_sha256
  end
end

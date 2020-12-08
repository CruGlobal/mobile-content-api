# frozen_string_literal: true

require "xml_util"

class Attachment < ActiveRecord::Base
  validates :file, attached: true
  validates :is_zipped, inclusion: {in: [true, false]}
  validates :resource, presence: true
  validates_with AttachmentValidator, if: :changed?
  validates_with AttachmentFilenameDuplicateValidator, if: :changed?

  belongs_to :resource

  has_one_attached :file
  validates :file, file_content_type: {
    allow: ["image/jpeg", "image/png", "image/gif", "image/jpg", "application/json"],
    if: -> { file.attached? }
  }

  before_validation :set_defaults
  before_save :save_sha256, if: :changed?
  after_save :update_filename, if: :changed?

  def changed?
    return true if filename != file.filename.to_s
    false
  end

  def url
    Rails.application.routes.url_helpers.rails_blob_url(file)
  end

  def generate_sha256
    XmlUtil.filename_sha(URI.parse(url).open.read)
  rescue NoMethodError, OpenURI::HTTPError
    file = attachment_changes["file"].attachable
    file ||= url
    XmlUtil.filename_sha(File.open(file).read)
  end

  private

  def set_defaults
    self.is_zipped ||= false
  end

  def save_sha256
    self.sha256 = generate_sha256
  end

  def update_filename
    self.filename = file.filename.to_s
    save!
  end
end

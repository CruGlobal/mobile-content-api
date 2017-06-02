# frozen_string_literal: true

class Attachment < ActiveRecord::Base
  validates :file, presence: true
  validates :is_zipped, inclusion: { in: [true, false] }
  validates :resource, presence: true, uniqueness: { scope: :file_file_name }

  belongs_to :resource

  has_attached_file :file
  validates_attachment :file, content_type: { content_type: %w(image/jpg image/jpeg image/png image/gif) }

  before_validation :set_defaults
  before_save :save_sha256

  private

  def set_defaults
    self.is_zipped ||= false
  end

  def save_sha256
    path = file.queued_for_write[:original].path
    self.sha256 = ApplicationHelper.generate_filename_sha(open(path).read)
  end
end

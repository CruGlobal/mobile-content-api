# frozen_string_literal: true

class AttachmentValidator < ActiveModel::Validator
  def validate(a)
    return unless Attachment.exists?(sha256: a.filename_sha, resource: a.resource)
    a.errors.add(:file, 'This file already exists for this resource')
  end
end

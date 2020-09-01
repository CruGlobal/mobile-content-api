# frozen_string_literal: true

class AttachmentValidator < ActiveModel::Validator
  def validate(model)
    return unless Attachment.exists?(sha256: model.generate_sha256, resource: model.resource)
    model.errors.add(:file, "This file already exists for this resource")
  end
end

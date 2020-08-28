# frozen_string_literal: true

class AttachmentValidator < ActiveModel::Validator
  def validate(model)
    file = model.attachment_changes['file'].attachable
    sha256 = XmlUtil.filename_sha(File.open(file).read)
    return unless Attachment.exists?(sha256: sha256, resource: model.resource)
    model.errors.add(:file, "This file already exists for this resource")
  end
end

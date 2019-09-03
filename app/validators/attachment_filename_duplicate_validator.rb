# frozen_string_literal: true

class AttachmentFilenameDuplicateValidator < ActiveModel::Validator
  def validate(model)
    Attachment.where(resource: model.resource).each do |attachment|
      if attachment.file.filename.to_s == model.file.filename.to_s
        model.errors.add(:file, 'This filename is duplicate for this resource')
      end
    end
  end
end

# frozen_string_literal: true

class AttachmentsController < SecureController
  def create
    Attachment.create!(params.permit(:key, :resource_id, :translation_id, :file))
    head :created
  end
end

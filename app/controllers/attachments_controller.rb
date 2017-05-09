# frozen_string_literal: true

class AttachmentsController < SecureController
  def create
    Attachment.create!(params.permit(permitted_params))
    head :created
  end

  def update
    load_attachment.update(params.permit(permitted_params))
    head :no_content
  end

  def destroy
    load_attachment.destroy
    head :no_content
  end

  private

  def load_attachment
    Attachment.find(params[:id])
  end

  def permitted_params
    [:key, :resource_id, :translation_id, :file]
  end
end

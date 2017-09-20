# frozen_string_literal: true

class AttachmentsController < ApplicationController
  before_action :authorize!, only: [:create, :update, :destroy]

  def download
    redirect_to load_attachment.file.url, status: :found
  end

  def create
    a = Attachment.create!(permitted_params)
    head :no_content, location: "attachments/#{a.id}"
  end

  def update
    load_attachment.update!(permitted_params)
    head :no_content
  end

  def destroy
    load_attachment.destroy!
    head :no_content
  end

  private

  def load_attachment
    Attachment.find(params[:id])
  end

  def permitted_params
    params.permit([:resource_id, :file, :is_zipped])
  end
end

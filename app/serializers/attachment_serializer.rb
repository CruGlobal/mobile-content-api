# frozen_string_literal: true

class AttachmentSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  type 'attachment'
  attributes :id, :file, :filename, :is_zipped, :sha256

  def file
    rails_blob_url(object.file)
  end

  def filename
    object.file.filename
  end

  belongs_to :resource
end

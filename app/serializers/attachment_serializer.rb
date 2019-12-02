# frozen_string_literal: true

class AttachmentSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  type "attachment"
  attributes :id, :file, :is_zipped, :sha256
  attribute :filename, key: "file-file-name"

  def file
    rails_blob_url(object.file, protocol: 'https')
  end

  def filename
    object.file.filename
  end

  belongs_to :resource
end

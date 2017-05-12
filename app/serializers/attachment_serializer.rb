# frozen_string_literal: true

class AttachmentSerializer < ActiveModel::Serializer
  type 'attachment'
  attributes :id, :file, :is_zipped, :file_file_name, :sha256

  belongs_to :resource
end

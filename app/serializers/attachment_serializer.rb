# frozen_string_literal: true

class AttachmentSerializer < ActiveModel::Serializer
  type 'attachment'
  attributes :id, :file, :is_zipped, :sha256

  belongs_to :resource
end

# frozen_string_literal: true

class AttachmentSerializer < ActiveModel::Serializer
  type 'attachment'
  attributes :id, :file, :is_zipped

  belongs_to :resource
end

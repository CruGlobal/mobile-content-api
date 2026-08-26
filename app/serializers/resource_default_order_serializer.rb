# frozen_string_literal: true

class ResourceDefaultOrderSerializer < ActiveModel::Serializer
  type "resource-default-order"
  attributes :position, :created_at, :updated_at
  attribute :lang

  belongs_to :resource
  belongs_to :language

  def lang
    object.language&.code
  end
end

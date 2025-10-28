# frozen_string_literal: true

class ResourceDefaultOrderSerializer < ActiveModel::Serializer
  type "resource-default-order"
  attributes :position, :lang, :created_at, :updated_at

  belongs_to :resource
end

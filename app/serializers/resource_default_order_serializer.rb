# frozen_string_literal: true

class ResourceDefaultOrderSerializer < ActiveModel::Serializer
  type "resource-default-order"
  attributes :position, :lang

  belongs_to :resource
end

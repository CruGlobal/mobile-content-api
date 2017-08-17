# frozen_string_literal: true

class ResourceTypeSerializer < ActiveModel::Serializer
  type 'resource_type'

  attributes :id, :name, :dtd_file
end

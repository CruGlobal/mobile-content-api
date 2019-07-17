# frozen_string_literal: true

class CustomManifestSerializer < ActiveModel::Serializer
  type 'custom-manifest'
  attributes :id, :structure

  belongs_to :resource
  belongs_to :language
end

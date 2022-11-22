# frozen_string_literal: true

class TranslatedAttributeSerializer < ActiveModel::Serializer
  type "translated-attribute"
  attributes :key, :onesky_phrase_id, :required

  belongs_to :resource
end

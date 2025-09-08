# frozen_string_literal: true

class TranslatedAttributeSerializer < ActiveModel::Serializer
  type "translated-attribute"
  attributes :key, :crowdin_phrase_id, :required

  belongs_to :resource
end

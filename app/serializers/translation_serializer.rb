# frozen_string_literal: true

class TranslationSerializer < ActiveModel::Serializer
  type 'translation'
  attributes :id, :is_published, :version, :manifest_name, :translated_name, :translated_description, :translated_tagline

  belongs_to :resource
  belongs_to :language
end

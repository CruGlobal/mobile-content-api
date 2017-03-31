# frozen_string_literal: true

class TranslationSerializer < ActiveModel::Serializer
  attributes :id, :resource_id, :translation_id, :is_published, :version

  belongs_to :resource
  belongs_to :translation

  has_many :custom_pages
end

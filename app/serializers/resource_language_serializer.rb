# frozen_string_literal: true

class ResourceLanguageSerializer < ActiveModel::Serializer
  attributes :id

  type "resource-language"

  belongs_to :resource
  belongs_to :language
  has_many :custom_pages
  has_many :custom_tips
  has_one :custom_manifest

  def type
    "resource-language"
  end

  def id
    "#{object.resource.id}-#{object.language.id}"
  end

  def attributes(*args)
    hash = super
    object.language_attributes.each { |attribute| hash["attr_#{attribute.key}"] = attribute.value }
    hash
  end
end

# frozen_string_literal: true
#
class ResourceLanguageSerializer < ActiveModel::Serializer
  attributes :id

  type "resource-language"

  belongs_to :resource
  belongs_to :language
  has_many :custom_pages
  has_many :custom_tips

  def attributes(*args)
    hash = super
    object.language_attributes.each { |attribute| hash["attr_#{attribute.key}"] = attribute.value }
    hash
  end
end

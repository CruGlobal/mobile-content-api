# frozen_string_literal: true
#
class ResourceLanguageSerializer < ActiveModel::Serializer
  attributes :id

  type "resource-language"

  belongs_to :resource
  belongs_to :language
  has_many :custom_pages
  has_many :custom_tips
end

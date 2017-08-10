# frozen_string_literal: true

class LanguageSerializer < ActiveModel::Serializer
  type 'language'
  attributes :id, :code, :name

  has_many :translations
  has_many :custom_pages
end

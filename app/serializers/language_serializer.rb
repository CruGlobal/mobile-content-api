# frozen_string_literal: true

class LanguageSerializer < ActiveModel::Serializer
  type 'language'
  attributes :id, :code

  has_many :translations
end

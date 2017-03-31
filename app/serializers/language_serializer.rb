# frozen_string_literal: true

class LanguageSerializer < ActiveModel::Serializer
  attributes :id, :abbreviation

  has_many :translations
end

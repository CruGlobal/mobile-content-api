# frozen_string_literal: true

class LanguageSerializer < ActiveModel::Serializer
  type "language"
  attributes :id, :code, :name, :direction
  attribute :force_language_name, key: :"force-language-name"

  has_many :translations
  has_many :custom_pages
  has_many :custom_tips
end

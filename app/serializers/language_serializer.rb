# frozen_string_literal: true

class LanguageSerializer < ActiveModel::Serializer
  type "language"
  attributes :id, :code, :name, :direction, :force_language_name

  has_many :translations
  has_many :custom_pages
  has_many :custom_tips
end

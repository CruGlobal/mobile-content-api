# frozen_string_literal: true

class LanguageSerializer < ActiveModel::Serializer
  type "language"
  attributes :id, :code, :name, :direction

  has_many :translations
  has_many :custom_pages
  has_many :custom_tips
end

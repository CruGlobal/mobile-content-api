# frozen_string_literal: true

class Language < ActiveRecord::Base
  has_many :translations
  has_many :custom_pages
  has_many :custom_tips
  has_many :translated_pages
  has_many :language_attributes

  validates :name, presence: true
  validates :code, presence: true
  validates_with LanguageValidator, on: :create
end

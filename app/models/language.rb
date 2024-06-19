# frozen_string_literal: true

class Language < ActiveRecord::Base
  has_many :translations, dependent: :restrict_with_error
  has_many :custom_pages, dependent: :restrict_with_error
  has_many :custom_tips, dependent: :restrict_with_error
  has_many :translated_pages, dependent: :restrict_with_error
  has_many :language_attributes, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true
  validates_with LanguageValidator, on: [:create, :update]
end

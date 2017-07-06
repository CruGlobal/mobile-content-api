# frozen_string_literal: true

class Language < ActiveRecord::Base
  has_many :translations
  has_many :custom_pages

  validates :name, presence: true
  validates :code, presence: true
end

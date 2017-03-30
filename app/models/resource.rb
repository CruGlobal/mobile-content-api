# frozen_string_literal: true

class Resource < ActiveRecord::Base
  belongs_to :system
  has_many :translations
  has_many :pages

  def create_new_draft(language_id)
    language = Language.find(language_id)

    page_helper = PageHelper.new(self, language.abbreviation)
    page_helper.push_new_onesky_translation
    Translation.create(resource: self, language: language)
  end
end

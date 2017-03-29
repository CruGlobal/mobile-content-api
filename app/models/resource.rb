# frozen_string_literal: true

class Resource < ActiveRecord::Base
  belongs_to :system
  has_many :translations
  has_many :pages

  def create_new_draft(language_id)
    language = Language.find(language_id)

    PageHelper.push_new_onesky_translation(self, language.abbreviation)
    Translation.create(resource: self, language: language)
  end
end

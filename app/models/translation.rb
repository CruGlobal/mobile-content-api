# frozen_string_literal: true

class Translation < ActiveRecord::Base
  belongs_to :resource
  belongs_to :language
  has_many :translation_pages

  def add_new_version
    Translation.create(resource: resource, language: language, version: version + 1)
  end

  def self.latest_translation(resource_id, language_id)
    Translation.where(resource_id: resource_id, language_id: language_id).order(version: :desc).first
  end
end

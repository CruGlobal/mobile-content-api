# frozen_string_literal: true

class Translation < ActiveRecord::Base
  belongs_to :resource
  belongs_to :language
  has_many :custom_pages

  def add_new_version
    Translation.create(resource: resource, language: language, version: version + 1)
  end

  def s3_uri
    "https://s3.amazonaws.com/#{ENV['GODTOOLS_V2_BUCKET']}/"\
    "#{resource.system.name}/#{resource.abbreviation}/#{language.abbreviation}.zip"
  end

  def self.latest_translation(resource_id, language_id)
    Translation.where(resource_id: resource_id, language_id: language_id).order(version: :desc).first
  end
end

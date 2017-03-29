# frozen_string_literal: true

require 's3_helper'

class Translation < ActiveRecord::Base
  belongs_to :resource
  belongs_to :language
  has_many :custom_pages

  before_destroy :prevent_destroy_published

  def add_new_version
    Translation.create(resource: resource, language: language, version: version + 1)
  end

  def s3_uri
    "https://s3.amazonaws.com/#{ENV['GODTOOLS_V2_BUCKET']}/"\
    "#{resource.system.name}/#{resource.abbreviation}/#{language.abbreviation}.zip"
  end

  def download_translated_page(page_filename)
    return PageHelper.download_translated_page(self, page_filename)
  rescue RestClient::ExceptionWithResponse => e
    return e.response
  end

  def edit_page_structure(page_id, structure)
    CustomPage.upsert(self, page_id, structure)
  end

  def publish
    S3Helper.push_translation(self)
    update(is_published: true)
  end

  def delete_draft!
    destroy!
    return :no_content
  rescue
    return :bad_request
  end

  def self.latest_translation(resource_id, language_id)
    Translation.where(resource_id: resource_id, language_id: language_id).order(version: :desc).first
  end

  private

  def prevent_destroy_published
    raise 'Cannot delete published drafts.' if is_published
  end
end

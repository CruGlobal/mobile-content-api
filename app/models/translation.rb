# frozen_string_literal: true

require 's3_helper'

class Translation < ActiveRecord::Base
  belongs_to :resource
  belongs_to :language
  has_many :custom_pages

  before_destroy :prevent_destroy_published

  def create_new_version
    Translation.create(resource: resource, language: language, version: version + 1)
  end

  def s3_uri
    "https://s3.amazonaws.com/#{ENV['GODTOOLS_V2_BUCKET']}/"\
    "#{resource.system.name}/#{resource.abbreviation}/#{language.abbreviation}/version_#{version}.zip"
  end

  def download_translated_page(page_filename)
    return RestClient.get "https://platform.api.onesky.io/1/projects/#{resource.onesky_project_id}/translations",
                          params: { api_key: ENV['ONESKY_API_KEY'], timestamp: AuthHelper.epoch_time_seconds,
                                    dev_hash: AuthHelper.dev_hash, locale: language.abbreviation,
                                    source_file_name: page_filename, export_file_name: page_filename }
  rescue RestClient::ExceptionWithResponse => e
    return e.response
  end

  def publish
    s3helper = S3Helper.new(self)
    s3helper.push_translation
    update(is_published: true)
  end

  def delete_draft!
    destroy!
    return :no_content
  rescue
    return :bad_request
  end

  def translated_pages
    translated_pages = []

    resource.pages.each do |resource_page|
      custom_pages.each do |custom_page|
        if resource_page.id == custom_page.page_id
          translated_pages.push(custom_page)
        else
          translated_pages.push(resource_page)
        end
      end
    end

    translated_pages
  end

  def self.latest_translation(resource_id, language_id)
    Translation.order(version: :desc).find_by(resource_id: resource_id, language_id: language_id)
  end

  private

  def prevent_destroy_published
    raise 'Cannot delete published drafts.' if is_published
  end
end

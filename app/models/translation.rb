# frozen_string_literal: true

require 's3_helper'

class Translation < ActiveRecord::Base
  belongs_to :resource
  belongs_to :language
  has_many :custom_pages

  before_destroy :prevent_destroy_published
  before_update :push_published_to_s3

  def create_new_version
    Translation.create(resource: resource, language: language, version: version + 1)
  end

  def s3_uri
    "https://s3.amazonaws.com/#{ENV['MOBILE_CONTENT_API_BUCKET']}/"\
    "#{resource.system.name}/#{resource.abbreviation}/#{language.abbreviation}/version_#{version}.zip"
  end

  def download_translated_page(page_filename)
    RestClient.get "https://platform.api.onesky.io/1/projects/#{resource.onesky_project_id}/translations",
                   params: { api_key: ENV['ONESKY_API_KEY'], timestamp: AuthHelper.epoch_time_seconds,
                             dev_hash: AuthHelper.dev_hash, locale: language.abbreviation,
                             source_file_name: page_filename, export_file_name: page_filename }
  end

  def update_draft(params)
    update(params.permit(:is_published))
  end

  def delete_draft!
    destroy!
    return :no_content
  rescue
    return :bad_request
  end

  def translated_pages
    resource.pages.map do |resource_page|
      custom_pages.find_by(page_id: resource_page.id) || resource_page
    end
  end

  def self.latest_translation(resource_id, language_id)
    Translation.order(version: :desc).find_by(resource_id: resource_id, language_id: language_id)
  end

  private

  def prevent_destroy_published
    raise 'Cannot delete published drafts.' if is_published
  end

  def push_published_to_s3
    return unless is_published

    p = JSON.parse(download_translated_page('name_description.xml'))
    self.translated_name = p['name']
    self.translated_description = p['description']

    s3helper = S3Helper.new(self)
    s3helper.push_translation
  end
end

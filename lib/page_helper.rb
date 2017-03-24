# frozen_string_literal: true
require 'rest-client'
require 'auth_helper'

class PageHelper
  def self.download_translated_page(translation, page_name)
    RestClient.get "https://platform.api.onesky.io/1/projects/#{translation.resource.one_sky_project_id}/translations",
                   params:
                     {
                       api_key: ENV['ONESKY_API_KEY'],
                       timestamp: AuthHelper.epoch_time_seconds,
                       dev_hash: AuthHelper.dev_hash,
                       locale: translation.language.abbreviation,
                       source_file_name: page_name,
                       export_file_name: page_name
                     }
  end

  def self.push_new_onesky_translation(resource, language_code)
    push_all_pages(resource, language_code)
    delete_temp_pages

    :created
  end

  private

  def push_all_pages(resource, language_code)
    resource.pages.each do |page|
      write_temp_file(page)

      begin
        RestClient.post "https://platform.api.onesky.io/1/projects/#{resource.one_sky_project_id}/files",
                        file: File.new("pages/#{page.filename}"),
                        file_format: 'HIERARCHICAL_JSON',
                        api_key: ENV['ONESKY_API_KEY'],
                        timestamp: AuthHelper.epoch_time_seconds,
                        locale: language_code,
                        dev_hash: AuthHelper.dev_hash,
                        multipart: true

      rescue RestClient::ExceptionWithResponse => e
        raise e
      end
    end
  end

  def write_temp_file(page)
    page_to_upload = {}
    page.translation_elements.each { |element| page_to_upload[element.id] = element.text }

    temp_file = File.open("pages/#{page.filename}", 'w')
    temp_file.puts page_to_upload.to_json
    temp_file.close
  end

  def delete_temp_pages
    temp_dir = Dir.glob('pages/*')
    temp_dir.each { |file| File.delete(file) }
  end
end

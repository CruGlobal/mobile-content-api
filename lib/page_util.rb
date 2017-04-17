# frozen_string_literal: true
require 'rest-client'
require 'auth_util'

class PageUtil
  def initialize(resource, language_code)
    @resource = resource
    @language_code = language_code
  end

  def push_new_onesky_translation
    push_all_pages
    self.class.delete_temp_pages
  end

  def self.delete_temp_pages
    temp_dir = Dir.glob('pages/*')
    temp_dir.each { |file| File.delete(file) }
  end

  private

  def push_all_pages
    @resource.pages.each do |page|
      write_temp_file(page)

      # TODO: we might not need to push every page when we're creating a draft for a new language
      RestClient.post "https://platform.api.onesky.io/1/projects/#{@resource.onesky_project_id}/files",
                      file: File.new("pages/#{page.filename}"),
                      file_format: 'HIERARCHICAL_JSON',
                      api_key: ENV['ONESKY_API_KEY'],
                      timestamp: AuthUtil.epoch_time_seconds,
                      locale: @language_code,
                      dev_hash: AuthUtil.dev_hash,
                      multipart: true
    end
  end

  def write_temp_file(page)
    page_to_upload = {}
    page.translation_elements.each { |element| page_to_upload[element.id] = element.text }

    temp_file = File.open("pages/#{page.filename}", 'w')
    temp_file.puts page_to_upload.to_json
    temp_file.close
  end
end

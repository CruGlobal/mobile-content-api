# frozen_string_literal: true

require 'rest-client'
require 'auth_util'
require 'xml_util'

class PageUtil
  def initialize(resource, language_code)
    @resource = resource
    @language_code = language_code
  end

  # I don't think it's critical to push all these files every time a new language is added, but we might as well do so
  # because that will help keep OneSky up to date with the pages and phrases stored in the database.
  def push_new_onesky_translation(keep_existing_phrases = true)
    push_resource_pages(keep_existing_phrases)
    push_name_description
    push_translatable_attributes if @resource.uses_onesky?

    self.class.delete_temp_pages
  rescue StandardError => e
    self.class.delete_temp_pages
    raise e
  end

  def self.delete_temp_pages
    temp_dir = Dir.glob('pages/*')
    temp_dir.each { |file| File.delete(file) }
  end

  private

  def push_resource_pages(keep_existing_phrases)
    @resource.pages.each do |page|
      phrases = {}
      XmlUtil.translatable_nodes(Nokogiri::XML(page.structure)).each { |n| phrases[n['i18n-id']] = n.content }

      push_page(phrases, page.filename, keep_existing_phrases)
    end
  end

  def push_name_description
    phrases = { name: @resource.name, description: @resource.description }
    push_page(phrases, 'name_description.xml', false)
  end

  def push_translatable_attributes
    phrases = Hash[@resource.resource_attributes.where(is_translatable: true).pluck(:key, :value)]
    push_page(phrases, 'attributes.xml', true)
  end

  def push_page(phrases, filename, keep_existing_phrases)
    File.write("pages/#{filename}", phrases.to_json)

    Rails.logger.info "Pushing page with name: #{filename} to OneSky with language code: #{@language_code}"

    RestClient.post "https://platform.api.onesky.io/1/projects/#{@resource.onesky_project_id}/files",
                    file: File.new("pages/#{filename}"),
                    file_format: 'HIERARCHICAL_JSON',
                    api_key: ENV['ONESKY_API_KEY'],
                    timestamp: AuthUtil.epoch_time_seconds,
                    locale: @language_code,
                    dev_hash: AuthUtil.dev_hash,
                    multipart: true,
                    is_keeping_all_strings: keep_existing_phrases
  end
end

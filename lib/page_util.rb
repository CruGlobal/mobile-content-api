# frozen_string_literal: true

require 'rest-client'
require 'auth_util'
require 'xml_util'

class PageUtil
  def initialize(resource, language_code)
    @resource = resource
    @language_code = language_code
  end

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

    # TODO: we might not need to push every page when we're creating a draft for a new language
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

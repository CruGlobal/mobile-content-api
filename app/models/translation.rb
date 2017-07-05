# frozen_string_literal: true

require 's3_util'
require 'xml_util'

# rubocop:disable ClassLength
class Translation < ActiveRecord::Base
  belongs_to :resource
  belongs_to :language
  has_many :custom_pages
  has_many :translated_pages

  validates :version, presence: true
  validates :resource, presence: true
  validates :language, presence: true
  validates :is_published, inclusion: { in: [true, false] }
  validates_with DraftCreationValidator, on: :create

  before_destroy :prevent_destroy_published, if: :is_published
  before_update :push_published_to_s3
  before_validation :set_defaults, on: :create

  def s3_url
    obj = S3Util.s3_object(self)
    raise Error::NotFoundError, "Zip file not found in S3 for translation: #{id}" unless obj.exists?
    obj.public_url
  end

  def translated_page(page_id, strict)
    if resource.uses_onesky?
      onesky_translated_page(page_id, strict)
    else
      t = translated_pages.find_by(page_id: page_id)
      raise Error::TextNotFoundError, 'Translated page not found for this language.' if t.nil?
      t.value
    end
  end

  def update_draft(params)
    update!(params.permit(:is_published))
  end

  def object_name
    "#{resource.system.name}/#{resource.abbreviation}/#{language.code}/#{zip_name}"
  end

  def zip_name
    "version_#{version}.zip"
  end

  def self.latest_translation(resource_id, language_id)
    order(version: :desc).find_by(resource_id: resource_id, language_id: language_id)
  end

  private

  def onesky_translated_page(page_id, strict)
    page = Page.find(page_id)
    phrases = download_translated_phrases(page.filename)
    xml = Nokogiri::XML(page_structure(page_id))

    xml = onesky_translated_page_content(xml, phrases, strict)
    xml = onesky_translated_page_attributes(xml, phrases, strict)

    xml.to_s
  end

  def onesky_translated_page_content(xml, phrases, strict)
    XmlUtil.translatable_nodes(xml).each do |node|
      phrase_id = node['i18n-id']
      translated_phrase = phrases[phrase_id]

      if translated_phrase.present?
        node.content = translated_phrase
      elsif strict
        raise Error::TextNotFoundError, "Translated phrase not found: ID: #{phrase_id}, base text: #{node.content}"
      end
    end

    xml
  end

  def onesky_translated_page_attributes(xml, phrases, strict)
    XmlUtil.translatable_node_attrs(xml).each do |attribute|
      phrase_id = attribute.value
      new_name = attribute.name.slice('-i18n-id')
      translated_phrase = phrases[phrase_id]

      if translated_phrase.present?
        attribute.name = new_name
        attribute.value = translated_phrase
      elsif strict
        raise Error::TextNotFoundError, "Translated phrase not found: ID: #{phrase_id}, base text: #{attribute.value}"
      end
    end

    xml
  end

  def page_structure(page_id)
    custom_page = custom_pages.find_by(page_id: page_id)
    custom_page.nil? ? Page.find(page_id).structure : custom_page.structure
  end

  def prevent_destroy_published
    raise Error::TranslationError, "Cannot delete published draft: #{id}"
  end

  def push_published_to_s3
    return unless is_published

    name_desc_onesky if resource.uses_onesky?

    s3_util = S3Util.new(self)
    s3_util.push_translation
  end

  def name_desc_onesky
    logger.info "Updating translated name and description for translation with id: #{id}"

    p = download_translated_phrases('name_description.xml')
    self.translated_name = p['name']
    self.translated_description = p['description']
  end

  def download_translated_phrases(page_filename)
    logger.info "Downloading translated phrases for page: #{page_filename} with language: #{language.code}"

    response = RestClient.get "https://platform.api.onesky.io/1/projects/#{resource.onesky_project_id}/translations",
                              params: headers(page_filename)

    raise Error::TextNotFoundError, 'No translated phrases found for this language.' if response.code == 204
    JSON.parse(response.body)
  end

  def headers(page_filename)
    { api_key: ENV['ONESKY_API_KEY'], timestamp: AuthUtil.epoch_time_seconds, dev_hash: AuthUtil.dev_hash,
      locale: language.code, source_file_name: page_filename, export_file_name: page_filename }
  end

  def set_defaults
    self.version ||= 1
    self.is_published ||= false
  end
end

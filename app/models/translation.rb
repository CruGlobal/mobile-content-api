# frozen_string_literal: true

require 's3_util'
require 'xml_util'

class Translation < ActiveRecord::Base
  belongs_to :resource
  belongs_to :language
  has_many :custom_pages
  has_many :translated_pages

  validates :version, presence: true
  validates :resource, presence: true
  validates :language, presence: true
  validates :is_published, inclusion: { in: [true, false] }

  before_destroy :prevent_destroy_published
  before_update :push_published_to_s3
  before_validation :set_defaults, on: :create

  def create_new_version
    unless is_published
      raise Error::MultipleDraftsError,
            "Draft already exists for Resource ID: #{resource.id} and Language ID: #{language.id}"
    end

    Translation.create!(resource: resource, language: language, version: version + 1)
  end

  def s3_uri
    "https://s3.amazonaws.com/#{ENV['MOBILE_CONTENT_API_BUCKET']}/"\
    "#{resource.system.name}/#{resource.abbreviation}/#{language.code}/version_#{version}.zip"
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

  def self.latest_translation(resource_id, language_id)
    order(version: :desc).find_by(resource_id: resource_id, language_id: language_id)
  end

  private

  def onesky_translated_page(page_id, strict)
    page = Page.find(page_id)
    phrases = download_translated_phrases(page.filename)

    xml = Nokogiri::XML(page_structure(page_id))
    XmlUtil.translatable_nodes(xml).each do |node|
      phrase_id = node['i18n-id']
      translated_phrase = phrases[phrase_id]

      if translated_phrase.present?
        node.content = translated_phrase
      elsif strict
        raise Error::TextNotFoundError, "Translated phrase not found: ID: #{phrase_id}, base text: #{node.content}"
      end
    end

    xml.to_s
  end

  def page_structure(page_id)
    custom_page = custom_pages.find_by(page_id: page_id)
    custom_page.nil? ? Page.find(page_id).structure : custom_page.structure
  end

  def prevent_destroy_published
    raise Error::TranslationError, "Cannot delete published draft: #{id}" if is_published
  end

  def push_published_to_s3
    return unless is_published

    name_desc_onesky if resource.uses_onesky?

    s3_util = S3Util.new(self)
    s3_util.push_translation
  end

  def name_desc_onesky
    p = download_translated_phrases('name_description.xml')
    self.translated_name = p['name']
    self.translated_description = p['description']
  end

  def download_translated_phrases(page_filename)
    response = RestClient.get "https://platform.api.onesky.io/1/projects/#{resource.onesky_project_id}/translations",
                              params: { api_key: ENV['ONESKY_API_KEY'], timestamp: AuthUtil.epoch_time_seconds,
                                        dev_hash: AuthUtil.dev_hash, locale: language.code,
                                        source_file_name: page_filename, export_file_name: page_filename }

    raise Error::TextNotFoundError, 'No translated phrases found for this language.' if response.code == 204
    JSON.parse(response.body)
  end

  def set_defaults
    self.version ||= 1
    self.is_published ||= false
  end
end

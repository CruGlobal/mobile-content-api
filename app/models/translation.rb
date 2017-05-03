# frozen_string_literal: true

require 's3_util'

class Translation < ActiveRecord::Base
  belongs_to :resource
  belongs_to :language
  has_many :custom_pages

  validates :version, presence: true
  validates :resource, presence: true
  validates :language, presence: true
  validates :is_published, inclusion: { in: [true, false] }

  before_destroy :prevent_destroy_published
  before_update :push_published_to_s3
  before_validation :set_defaults, on: :create

  def create_new_version
    Translation.create(resource: resource, language: language, version: version + 1)
  end

  def s3_uri
    "https://s3.amazonaws.com/#{ENV['MOBILE_CONTENT_API_BUCKET']}/"\
    "#{resource.system.name}/#{resource.abbreviation}/#{language.code}/version_#{version}.zip"
  end

  def build_translated_page(page_id, strict)
    page = Page.find(page_id)
    phrases = JSON.parse(download_translated_phrases(page.filename))

    xml = page_structure(page_id)
    xml.xpath('//content:text[@i18n-id]').each do |node|
      translated_phrase = phrases[node['i18n-id']]

      if translated_phrase.present?
        node.content = translated_phrase
      elsif strict
        raise Error::PhraseNotFoundError, 'Translated phrase not found.' if strict
      end
    end

    xml.to_s
  end

  # TODO: parse JSON here?
  def download_translated_phrases(page_filename)
    RestClient.get "https://platform.api.onesky.io/1/projects/#{resource.onesky_project_id}/translations",
                   params: { api_key: ENV['ONESKY_API_KEY'], timestamp: AuthUtil.epoch_time_seconds,
                             dev_hash: AuthUtil.dev_hash, locale: language.code,
                             source_file_name: page_filename, export_file_name: page_filename }
  end

  def update_draft(params)
    update(params.permit(:is_published))
  end

  def self.latest_translation(resource_id, language_id)
    order(version: :desc).find_by(resource_id: resource_id, language_id: language_id)
  end

  private

  def page_structure(page_id)
    custom_page = custom_pages.find_by(page_id: page_id)
    structure = custom_page.nil? ? Page.find(page_id).structure : custom_page.structure
    Nokogiri::XML(structure)
  end

  def prevent_destroy_published
    raise Error::TranslationError, 'Cannot delete published drafts.' if is_published
  end

  def push_published_to_s3
    return unless is_published

    p = JSON.parse(download_translated_phrases('name_description.xml'))
    self.translated_name = p['name']
    self.translated_description = p['description']

    s3_util = S3Util.new(self)
    s3_util.push_translation
  end

  def set_defaults
    self.version ||= 1
    self.is_published ||= false
  end
end

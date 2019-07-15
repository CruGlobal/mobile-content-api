# frozen_string_literal: true

class Translation < ActiveRecord::Base
  include XML::Translatable

  belongs_to :resource
  belongs_to :language

  validates :version, presence: true, uniqueness: { scope: [:resource, :language] }
  validates :resource, presence: true
  validates :language, presence: true
  validates :is_published, inclusion: { in: [true, false] }
  validates_with DraftCreationValidator, on: :create
  validates_with UsesOneskyValidator

  before_destroy :prevent_destroy_published, if: :is_published
  before_update :push_published_to_s3
  before_validation :set_defaults, on: :create

  def s3_url
    obj = Package.s3_object(self)
    raise Error::NotFoundError, "Zip file not found in S3 for translation: #{id}" unless obj.exists?
    obj.public_url
  end

  def translated_page(page_id, strict)
    page = Page.find(page_id)
    phrases = download_translated_phrases(page.filename)
    xml = Nokogiri::XML(page_structure(page_id))

    xml = translate_node_content(xml, phrases, strict)
    xml = translate_node_attributes(xml, phrases, strict)

    xml.to_s
  end

  def create_new_version
    Translation.create!(resource: resource, language: language, version: version + 1)
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

  def manifest_translated_phrases
    @manifest_translated_phrases ||= download_translated_phrases('name_description.xml')
  end

  private

  def page_structure(page_id)
    custom_page = language.custom_pages.find_by(page_id: page_id)
    custom_page.nil? ? Page.find(page_id).structure : custom_page.structure
  end

  def prevent_destroy_published
    raise Error::TranslationError, "Cannot delete published draft: #{id}"
  end

  def push_published_to_s3
    return unless is_published

    name_desc_onesky if resource.uses_onesky?

    Package.new(self).push_to_s3
  end

  def name_desc_onesky
    logger.info "Updating translated name and description for translation with id: #{id}"

    p = manifest_translated_phrases
    self.translated_name = p['name']
    self.translated_description = p['description']
    self.translated_tagline = p['tagline']
  end

  def download_translated_phrases(filename)
    OneSky.download_translated_phrases(filename, language_code: language.code, project_id: resource.onesky_project_id)
  end

  def set_defaults
    self.version ||= 1
    self.is_published ||= false
  end
end

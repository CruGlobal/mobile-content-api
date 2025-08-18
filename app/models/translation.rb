# frozen_string_literal: true

class Translation < ActiveRecord::Base
  include Xml::Filterable
  include Xml::Translatable

  belongs_to :resource, touch: true
  belongs_to :language
  has_many :translation_attributes

  validates :version, presence: true, uniqueness: {scope: [:resource, :language]}
  validates :resource, presence: true
  validates :language, presence: true
  validates :is_published, inclusion: {in: [true, false]}
  validates_with DraftCreationValidator, on: :create
  validates_with UsesCrowdinValidator

  before_destroy :prevent_destroy_published, if: :is_published
  before_validation :set_defaults, on: :create

  def s3_url
    obj = Package.s3_object(self)
    raise Error::NotFoundError, "Zip file not found in S3 for translation: #{id}" unless obj.exists?
    obj.public_url
  end

  def translated_page(page_id, strict)
    phrases = download_translated_phrases
    xml = Nokogiri::XML(page_structure(page_id))

    xml = filter_node_content(xml, self)
    xml = translate_node_content(xml, phrases, strict)
    xml = translate_node_attributes(xml, phrases, strict)

    xml.to_s
  end

  def translated_tip(tip_id, strict)
    phrases = download_translated_phrases
    xml = Nokogiri::XML(tip_structure(tip_id))

    xml = filter_node_content(xml, self)
    xml = translate_node_content(xml, phrases, strict)
    xml = translate_node_attributes(xml, phrases, strict)

    xml.to_s
  end

  def create_new_version
    Translation.create!(resource: resource, language: language, version: version + 1)
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

  # Returns the manifest (XML) content to use for this translation (language).
  # @return [String] or nil if no manifest exists
  def resolve_manifest
    resource.custom_manifests.find_by(language_id: language_id)&.structure || resource.manifest
  end

  def manifest_translated_phrases
    @manifest_translated_phrases ||= download_translated_phrases
  end

  def push_published_to_s3
    return if is_published

    if resource.uses_crowdin?
      ActiveRecord::Base.transaction do
        phrases = manifest_translated_phrases
        name_desc_crowdin(phrases)
        create_translated_attributes(phrases)
      end
    end

    Package.new(self).push_to_s3
    update(is_published: true, publishing_errors: nil)
  end

  private

  def page_structure(page_id)
    custom_page = language.custom_pages.find_by(page_id: page_id)
    custom_page.nil? ? Page.find(page_id).structure : custom_page.structure
  end

  def tip_structure(tip_id)
    custom_tip = language.custom_tips.find_by(tip_id: tip_id)
    custom_tip.nil? ? Tip.find(tip_id).structure : custom_tip.structure
  end

  def prevent_destroy_published
    raise Error::TranslationError, "Cannot delete published draft: #{id}"
  end

  def name_desc_crowdin(phrases)
    logger.info "Updating translated name and description for translation with id: #{id}"

    self.translated_name = phrases["name"]
    self.translated_description = phrases["description"]
    self.translated_tagline = phrases["tagline"]
  end

  def create_translated_attributes(phrases)
    translation_attribute_ids = []
    resource.translated_attributes.each do |translated_attribute|
      translation = phrases[translated_attribute.crowdin_phrase_id]

      if translation.present?
        translation_attribute = translation_attributes.where(key: translated_attribute.key).first_or_initialize
        translation_attribute.update(value: translation)
        translation_attribute_ids << translation_attribute.id
      elsif translated_attribute.required
        raise Error::TextNotFoundError, "Translated phrase not found: ID: #{translated_attribute.crowdin_phrase_id}"
      end
    end

    translation_attributes.where.not(id: translation_attribute_ids).delete_all
  end

  def download_translated_phrases
    CrowdinService.download_translated_phrases(language_code: language.code, project_id: resource.crowdin_project_id)
  end

  def set_defaults
    self.version ||= 1
    self.is_published ||= false
  end
end

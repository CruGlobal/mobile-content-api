# frozen_string_literal: true

class Resource < ActiveRecord::Base
  belongs_to :system
  belongs_to :resource_type
  has_many :translations
  has_many :pages, -> { order(:position) }, inverse_of: :resource
  has_many :tips
  has_many :resource_attributes, class_name: "Attribute"
  has_many :language_attributes
  has_many :attachments
  has_many :translated_pages
  has_many :translated_attributes
  has_many :custom_manifests
  has_many :resource_tool_groups
  has_many :tool_groups, through: :resource_tool_groups

  belongs_to :metatool, optional: true, class_name: "Resource"
  belongs_to :default_variant, optional: true, class_name: "Resource"
  has_many :variants, class_name: "Resource", foreign_key: :metatool_id
  validate :metatool_reference_is_metatool, if: :metatool
  validate :default_variant_reference_is_valid, if: :default_variant

  validates :name, presence: true
  validates :abbreviation, presence: true, uniqueness: true
  validates :system, presence: true
  validates :resource_type, presence: true
  validates :manifest, xml: true, if: :manifest?

  scope :system_name, lambda { |name|
    t = System.arel_table
    where system: System.find_by(t[:name].matches(name))
  }

  def self.index_cache_key(resources, include_param:, fields_param:)
    "cache::#{resources.cache_key_with_version}/#{include_param.hash}/#{fields_param.hash}"
  end

  def set_data_attributes!(data_attrs)
    data_attrs.each_pair do |key, value|
      attr_name = key[/^attr-(.*)$/, 1]
      next unless attr_name
      attr_name.tr!("-", "_")
      attribute = resource_attributes.where(key: attr_name).first_or_initialize
      if value.nil?
        attribute.destroy unless attribute.new_record?
      else
        attribute.value = value.to_s
        attribute.save!
      end
    end
  end

  def uses_crowdin?
    crowdin_project_id.present?
  end

  def create_draft(language_id)
    translation = Translation.latest_translation(id, language_id)

    return translation if translation && !translation.is_published

    if translation&.is_published
      translation.create_new_version
    else
      create_first_draft(language_id)
    end
  end

  def latest_translations
    latest(true)
  end

  def latest_drafts_translations
    latest
  end

  delegate :name, to: :resource_type, prefix: true

  private

  def create_first_draft(language_id)
    language = Language.find(language_id)

    # TODO: disable this to prevent the API from overwriting existing translations within OneSky.
    # TODO: This will probably need to be revisited -DF
    # PageClient.new(self, language.code).push_new_onesky_translation
    Translation.create!(resource: self, language: language)
  end

  # returns the Translation with the highest version for each Language and this Resource
  def latest(is_published = [true, false])
    Translation.joins("inner join (#{latest_versions(is_published).to_sql}) as max_table
                       on translations.version = max_table.max_version
                       and translations.language_id = max_table.language_id
                       and translations.resource_id = max_table.resource_id")
      .includes(:language).order("languages.name ASC")
  end

  # returns the highest version for each Language and this Resource
  def latest_versions(is_published)
    Translation.select(:language_id, :resource_id, "max(version) as max_version")
      .where(resource_id: id, is_published: is_published)
      .group(:language_id, :resource_id)
  end

  def metatool_reference_is_metatool
    unless metatool.resource_type&.name == "metatool"
      errors.add :metatool, "is not a metatool"
    end
  end

  def default_variant_reference_is_valid
    unless resource_type&.name == "metatool"
      errors.add :default_variant, "should not be present unless the resource is a metatool"
    end

    unless variants.include?(default_variant)
      errors.add :default_variant, "is not a valid variant"
    end
  end
end

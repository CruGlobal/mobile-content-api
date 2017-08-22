# frozen_string_literal: true

class Resource < ActiveRecord::Base
  belongs_to :system
  belongs_to :resource_type
  has_many :translations
  has_many :pages
  has_many :resource_attributes, class_name: 'Attribute'
  has_many :views
  has_many :attachments
  has_many :translated_pages

  validates :name, presence: true
  validates :abbreviation, presence: true, uniqueness: true
  validates :system, presence: true
  validates :resource_type, presence: true
  validates :manifest, xml: true, if: :manifest?

  scope :system_name, lambda { |name|
    t = System.arel_table
    where system: System.find_by(t[:name].matches(name))
  }

  def uses_onesky?
    onesky_project_id.present?
  end

  def create_new_draft(language_id)
    language = Language.find(language_id)

    # TODO: disable this to prevent the API from overwriting existing translations within OneSky.
    # TODO: This will probably need to be revisited -DF
    # PageClient.new(self, language.code).push_new_onesky_translation
    Translation.create!(resource: self, language: language)
  end

  def latest_translations
    latest(true)
  end

  def latest_drafts_translations
    latest
  end

  def total_views
    views.all.sum(:quantity)
  end

  delegate :name, to: :resource_type, prefix: true

  private

  # returns the Translation with the highest version for each Language and this Resource
  def latest(is_published = [true, false])
    Translation.joins("inner join (#{latest_versions(is_published).to_sql}) as max_table
                       on translations.version = max_table.max_version
                       and translations.language_id = max_table.language_id
                       and translations.resource_id = max_table.resource_id")
  end

  # returns the highest version for each Language and this Resource
  def latest_versions(is_published)
    Translation.select(:language_id, :resource_id, 'max(version) as max_version')
               .where(resource_id: id, is_published: is_published)
               .group(:language_id, :resource_id)
  end
end

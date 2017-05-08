# frozen_string_literal: true

class Resource < ActiveRecord::Base
  belongs_to :system
  has_many :translations
  has_many :pages
  has_many :resource_attributes, class_name: 'Attribute'
  has_many :views

  validates :name, presence: true
  validates :abbreviation, presence: true, uniqueness: true
  validates :system, presence: true

  scope :system_name, lambda { |name|
    t = System.arel_table
    where system: System.find_by(t[:name].matches(name))
  }

  def create_new_draft(language_id)
    language = Language.find(language_id)

    PageUtil.new(self, language.code).push_new_onesky_translation
    Translation.create(resource: self, language: language)
  end

  # Returns the latest translation for each language.  In more detailed terms, the inner query returns the highest
  # version for the resource/language combination. The outer query then finds the translation matching that version.
  def latest_translations
    Translation.find_by_sql("select T.* from translations T inner join (select language_id, resource_id, max(version) as
                            max_version from translations where is_published = true and resource_id = #{id} group
                            by language_id, resource_id) as max_table on T.version = max_table.max_version and
                            T.language_id = max_table.language_id and T.resource_id = max_table.resource_id")
  end

  def total_views
    views.all.sum(:quantity)
  end
end

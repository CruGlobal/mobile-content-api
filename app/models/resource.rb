# frozen_string_literal: true

class Resource < ActiveRecord::Base
  belongs_to :system
  has_many :translations
  has_many :pages

  def create_new_draft(language_id)
    language = Language.find(language_id)

    page_util = PageUtil.new(self, language.abbreviation)
    page_util.push_new_onesky_translation
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
end

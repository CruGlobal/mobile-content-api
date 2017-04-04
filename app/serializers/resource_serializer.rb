# frozen_string_literal: true

class ResourceSerializer < ActiveModel::Serializer
  attributes :id, :name, :abbreviation, :onesky_project_id

  belongs_to :system

  has_many :translations
  has_many :pages

  has_many :latest_translations

  def latest_translations
    Translation.find_by_sql("select T.* from translations T inner join (select language_id, resource_id, max(version) as
                            max_version from translations where is_published = true and resource_id = #{object.id} group
                            by language_id, resource_id) as max_table on T.version = max_table.max_version and
                            T.language_id = max_table.language_id and T.resource_id = max_table.resource_id")
  end
end

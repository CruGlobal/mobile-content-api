# frozen_string_literal: true

class ResourceSerializer < ActiveModel::Serializer
  type 'resource'
  attributes :id, :name, :abbreviation, :description, :onesky_project_id, :total_views

  belongs_to :system

  has_many :translations
  has_many :latest_translations, key: 'latest-translations'
  has_many :pages

  def attributes(*args)
    hash = super
    object.resource_attributes.each { |r| hash["attr_#{r.key}"] = r.value }
    hash
  end
end

# frozen_string_literal: true

class ResourceSerializer < ActiveModel::Serializer
  type 'resource'
  attributes :id, :name, :content_type, :abbreviation, :description, :onesky_project_id, :total_views

  belongs_to :system

  has_many :translations
  has_many :latest_translations, key: 'latest-translations'
  has_many :pages
  has_many :attachments

  def attributes(*args)
    hash = super
    object.resource_attributes.each { |attribute| hash["attr_#{attribute.key}"] = attribute.value }
    hash
  end
end

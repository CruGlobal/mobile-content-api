# frozen_string_literal: true

class ResourceSerializer < ActiveModel::Serializer
  type 'resource'
  attributes :id, :name, :abbreviation, :description, :onesky_project_id, :total_views, :manifest
  attribute :resource_type_name, key: 'resource-type'

  belongs_to :system

  has_many :translations
  has_many :latest_translations, key: 'latest-translations'
  has_many :latest_drafts_translations, key: 'latest_drafts_translations'
  has_many :pages
  has_many :attachments
  has_many :custom_manifests, key: 'custom-manifests'

  def attributes(*args)
    hash = super
    object.resource_attributes.each { |attribute| hash["attr_#{attribute.key}"] = attribute.value }
    hash
  end
end

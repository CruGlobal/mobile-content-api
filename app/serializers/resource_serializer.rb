# frozen_string_literal: true

class ResourceSerializer < ActiveModel::Serializer
  type "resource"
  attributes :id, :name, :abbreviation, :description, :onesky_project_id, :manifest
  attribute :resource_type_name, key: :"resource-type"
  attribute :total_views, key: :"total-views"

  belongs_to :system
  belongs_to :metatool, if: -> { object&.resource_type&.name != "metatool" }

  has_many :latest_translations, key: "latest-translations"
  has_many :latest_drafts_translations, key: "latest-drafts-translations"
  has_many :pages
  has_many :tips
  has_many :attachments
  has_many :custom_manifests, key: "custom-manifests"
  has_many :variants, if: -> { object&.resource_type&.name == "metatool" }
  has_many :translated_attributes, key: "translated-attributes"

  belongs_to :default_variant, key: "default-variant", if: -> { object&.resource_type&.name == "metatool" }

  def attributes(requested_attrs = nil, reload = false)
    hash = super
    object.resource_attributes.each { |attribute|
      key = "attr-#{attribute.key}".tr("_", "-").to_sym
      next unless requested_attrs.nil? || requested_attrs.include?(key)
      hash[key] = attribute.value
    }
    hash
  end
end

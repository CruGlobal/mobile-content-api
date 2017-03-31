# frozen_string_literal: true

class ResourceSerializer < ActiveModel::Serializer
  attributes :id, :system_id, :name, :abbreviation, :onesky_project_id

  belongs_to :system

  has_many :translations
  has_many :pages
end

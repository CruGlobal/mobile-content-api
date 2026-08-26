# frozen_string_literal: true

class ResourceScorePermissionSerializer < ActiveModel::Serializer
  type "resource-score-permission"
  attributes :country, :created_at, :updated_at
  attribute :lang

  belongs_to :user
  belongs_to :language

  # "*" means every language in this country.
  def lang
    object.language&.code || ResourceScorePermission::ALL_LANGUAGES
  end
end

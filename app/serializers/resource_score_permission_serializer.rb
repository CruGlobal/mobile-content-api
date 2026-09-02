# frozen_string_literal: true

class ResourceScorePermissionSerializer < ActiveModel::Serializer
  type "resource-score-permission"
  attributes :country, :created_at, :updated_at
  attribute :lang

  # No :user linkage: the route (/users/:user_id/resource-score-permissions)
  # already fixes the owner, so emitting the same {type: "user", id: X} on every
  # row tells the client nothing and costs a User instantiation per row wherever
  # the per-request query cache is off. Add it back -- along with :user in the
  # controller's preloads -- only if a client actually needs it.
  belongs_to :language

  # "*" means every language in this country.
  def lang
    object.language&.code || ResourceScorePermission::ALL_LANGUAGES
  end
end

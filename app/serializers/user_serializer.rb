# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  type "user"
  attributes :sso_guid, :created_at
  has_many :favorite_tools, key: "favorite-tools"

  def created_at
    object.created_at.iso8601 # without this, the default serializer datetime will add 3 ms digits which we prefer not to have
  end
end

# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  type "user"
  attributes :sso_guid, :created_at, :given_name, :family_name, :name
  has_many :tools, key: "favorite-tools", serializer: ResourceFavoritedSerializer

  def created_at
    object.created_at.iso8601 # without this, the default serializer datetime will add 3 ms digits which we prefer not to have
  end

  def given_name
    object.first_name
  end

  def family_name
    object.last_name
  end
end

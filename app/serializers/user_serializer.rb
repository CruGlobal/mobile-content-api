# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  type "user"
  attributes :sso_guid, :created_at

  def created_at
    object.created_at.iso8601 # without this, the default serializer datetime will add 3 ms digits which Daniel prefers not to have
  end
end

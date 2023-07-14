# frozen_string_literal: true

class AuthTokenSerializer < ActiveModel::Serializer
  type "auth-token"
  attributes :token, :expiration
  attribute :user_id, key: "user-id"
  attribute :apple_refresh_token, if: -> { object.apple_refresh_token }
end

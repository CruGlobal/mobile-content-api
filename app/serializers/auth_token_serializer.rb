# frozen_string_literal: true

class AuthTokenSerializer < ActiveModel::Serializer
  type "auth-token"
  attributes :token, :expiration
end

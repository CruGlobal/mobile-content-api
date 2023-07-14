# frozen_string_literal: true

class AuthToken < ActiveModelSerializers::Model
  attributes :token, :expiration, :apple_refresh_token

  attr_writer :user

  class << self
    EXPIRATION_CLAIM = "exp"
    ISSUED_AT_CLAIM = "iat"
    HMAC = "HS256"

    def generic_token
      payload = {exp: new.expiration.to_i}
      encode(payload)
    end

    def encode(payload)
      payload = add_issued_at(payload)
      ::JWT.encode(payload, password, HMAC, typ: "JWT")
    end

    def decode!(token)
      ::JWT.decode(token.to_s, password, true, algorithm: HMAC)
    end

    def decode(token)
      decode!(token)
    rescue JWT::DecodeError
      nil
    end

    def jwt?(token)
      decode!(token).present?
    rescue ::JWT::DecodeError => e
      e.message != "Not enough or too many segments"
    end

    private

    def password
      return ENV["JSON_WEB_TOKEN_SECRET"] unless Rails.env.test?

      # in test env we don't want to expose prod secret
      ENV["JSON_WEB_TOKEN_SECRET_TEST"] || "#{ENV["JSON_WEB_TOKEN_SECRET"]}test"
    end

    def add_issued_at(payload)
      payload = payload.with_indifferent_access
      payload[ISSUED_AT_CLAIM] = Time.zone.now.to_i
      payload
    end
  end

  def token
    if @user
      payload = {user_id: @user.id, exp: expiration.to_i}
      self.class.encode(payload)
    else
      self.class.generic_token
    end
  end

  def expiration
    24.hours.from_now
  end

  def user_id
    @user&.id
  end
end

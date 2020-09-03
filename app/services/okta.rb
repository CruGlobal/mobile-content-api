# frozen_string_literal: true

class Okta
  include HTTParty
  LEEWAY = 0
  base_uri ENV.fetch("OKTA_SERVER_URL")

  class << self
    def find_user_by_id_token(id_token)
      info = validate_okta_id_token(id_token)
      find_user(info) || create_user(info)
    rescue JWT::DecodeError => e
      raise Okta::FailedAuthentication, e.message
    end

    private

    def find_user(user_info)
      User.find_by(sso_guid: user_info[:sso_guid])
    end

    def create_user(user_info)
      User.create!(user_info)
    end

    def validate_okta_id_token(id_token)
      payload = transform_jwt_payload JWT.decode(id_token, nil, true, jwt_options).first
      raise "ID Token does not include sso guid, make sure login scope includes profile" unless payload[:sso_guid]
      payload
    end

    def transform_jwt_payload(payload)
      {
        email: payload["email"],
        first_name: payload["given_name"],
        last_name: payload["family_name"],
        sso_guid: payload["ssoguid"]
      }.with_indifferent_access
    end

    # based on https://github.com/CruGlobal/omniauth-oktaoauth/blob/e78ffb420cb9ab89fd8951d9fe8a20f175c41618/lib/omniauth/strategies/oktaoauth.rb#L97-L108
    def jwt_options
      {
        algorithm: "RS256",
        jwks: fetch_jwks,
        verify_iss: true,
        verify_aud: true,
        iss: ENV["OKTA_SERVER_PATH"],
        aud: ENV["OKTA_SERVER_AUDIENCE"].split(","),
        verify_expiration: true,
        verify_not_before: true,
        verify_iat: true,
        verify_jti: false,
        leeway: LEEWAY
      }
    end

    def fetch_jwks
      path = if ENV["OKTA_SERVER_ID"].present?
        "/oauth2/#{ENV["OKTA_SERVER_ID"]}/v1/keys"
      else
        "/oauth2/v1/keys"
      end
      response = get(path)
      JSON.parse(response.body, symbolize_names: true)
    end
  end

  class FailedAuthentication < StandardError
  end
end

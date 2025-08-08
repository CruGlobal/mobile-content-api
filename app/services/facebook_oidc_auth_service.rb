# frozen_string_literal: true

require "jwt"
require "net/http"

class FacebookOidcAuthService < BaseAuthService
  class << self
    private

    def primary_key
      :facebook_user_id
    end

    def expected_fields
      %w[user_id]
    end

    def decode_token(id_token)
      jwks = fetch_facebook_jwks
      jwt_payload = JWT.decode(id_token, nil, true, {
        algorithms: ["RS256"],
        jwks: jwks,
        verify_aud: true,
        aud: ENV.fetch("FACEBOOK_APP_ID"),
        verify_iss: true,
        iss: "https://www.facebook.com"
      })[0]

      # Map OIDC claims to expected format for consistency with FacebookAuthService
      {
        "user_id" => jwt_payload["sub"], # sub is the App-Scoped ID (same as existing facebook_user_id)
        "aud" => jwt_payload["aud"],
        "iss" => jwt_payload["iss"],
        "exp" => jwt_payload["exp"],
        "email" => jwt_payload["email"],
        "name" => jwt_payload["name"],
        "given_name" => jwt_payload["given_name"],
        "family_name" => jwt_payload["family_name"],
        "picture" => jwt_payload["picture"]
      }
    rescue JWT::ExpiredSignature
      raise FailedAuthentication, "ID token has expired"
    rescue JWT::InvalidIssuerError
      raise FailedAuthentication, "Invalid issuer in ID token"
    rescue JWT::DecodeError => e
      raise FailedAuthentication, "Failed to decode ID token: #{e.message}"
    end

    def remote_user_id(decoded_token, user_atts = {})
      decoded_token["user_id"]
    end

    def validate_token!(_id_token, decoded_token)
      raise FailedAuthentication, "Error validating ID token with Facebook: token is not valid" unless
        decoded_token["user_id"] && decoded_token["aud"] && decoded_token["iss"]
    end

    def extract_user_atts(_id_token, decoded_token)
      user_attributes = {}

      # Only set attributes if they exist in the token
      user_attributes[:email] = decoded_token["email"] if decoded_token["email"]
      user_attributes[:name] = decoded_token["name"] if decoded_token["name"]
      user_attributes[:first_name] = decoded_token["given_name"] if decoded_token["given_name"]
      user_attributes[:last_name] = decoded_token["family_name"] if decoded_token["family_name"]

      # Set facebook_user_id to maintain consistency with existing users
      user_attributes[:facebook_user_id] = decoded_token["user_id"]

      user_attributes.with_indifferent_access
    end

    def fetch_facebook_jwks
      @facebook_jwks ||= begin
        uri = URI("https://www.facebook.com/.well-known/oauth/openid-configuration")
        response = Net::HTTP.get_response(uri)
        raise FailedAuthentication, "Failed to fetch Facebook OpenID configuration" unless response.is_a?(Net::HTTPSuccess)

        openid_config = JSON.parse(response.body)
        jwks_uri = openid_config["jwks_uri"]

        jwks_response = Net::HTTP.get_response(URI(jwks_uri))
        raise FailedAuthentication, "Failed to fetch Facebook JWKS" unless jwks_response.is_a?(Net::HTTPSuccess)

        JSON.parse(jwks_response.body)
      end
    end
  end

  class FailedAuthentication < BaseAuthService::FailedAuthentication
  end
end

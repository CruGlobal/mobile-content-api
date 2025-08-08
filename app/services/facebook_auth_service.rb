# frozen_string_literal: true

require "jwt"
require "net/http"

class FacebookAuthService < BaseAuthService
  BASE_URI = "https://graph.facebook.com"
  base_uri BASE_URI

  class << self
    # New method specifically for OIDC ID tokens
    def find_user_by_id_token(id_token, create_user)
      decoded_token = decode_id_token(id_token)
      validate_id_token!(id_token, decoded_token)
      validate_expected_oidc_fields!(decoded_token)

      user_atts = extract_oidc_user_atts(decoded_token)
      setup_user(remote_user_id_from_oidc(decoded_token), user_atts, create_user)
    rescue JSON::ParserError, JWT::DecodeError => e
      raise FailedAuthentication, "#{e.class.name}: #{e.message}"
    end

    private

    def expected_fields
      %w[user_id]
    end

    def expected_fields_from_get_fields
      %w[id email]
    end

    def expected_oidc_fields
      %w[sub aud iss]
    end

    # Existing access token validation (unchanged)
    def decode_token(input_token)
      decoded_token = JSON.parse(get("/debug_token", query: {input_token: input_token, access_token: "#{ENV.fetch("FACEBOOK_APP_ID")}|#{ENV.fetch("FACEBOOK_APP_SECRET")}"}).body)
      raise FailedAuthentication, "Error validating access_token with Facebook: #{decoded_token.dig("data", "error")}" if
        decoded_token.dig("data", "error")
      raise FailedAuthentication, "Error decoding access_token with Facebook" unless
        decoded_token.is_a?(Hash) && decoded_token["data"]
      decoded_token["data"]
    end

    # New OIDC ID token validation
    def decode_id_token(id_token)
      jwks = fetch_facebook_jwks
      decoded_token = JWT.decode(id_token, nil, true, {
        algorithms: ["RS256"],
        jwks: jwks,
        verify_aud: true,
        aud: ENV.fetch("FACEBOOK_APP_ID"),
        verify_iss: true,
        iss: "https://www.facebook.com"
      })[0]

      # Map OIDC claims to expected format for consistency
      {
        "user_id" => decoded_token["sub"], # sub is the App-Scoped ID (same as existing facebook_user_id)
        "aud" => decoded_token["aud"],
        "iss" => decoded_token["iss"],
        "exp" => decoded_token["exp"],
        "email" => decoded_token["email"],
        "name" => decoded_token["name"],
        "given_name" => decoded_token["given_name"],
        "family_name" => decoded_token["family_name"],
        "picture" => decoded_token["picture"]
      }
    rescue JWT::ExpiredSignature
      raise FailedAuthentication, "ID token has expired"
    rescue JWT::InvalidIssuerError
      raise FailedAuthentication, "Invalid issuer in ID token"
    rescue JWT::DecodeError => e
      raise FailedAuthentication, "Failed to decode ID token: #{e.message}"
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

    def validate_expected_oidc_fields!(decoded_token)
      # Check for the mapped user_id field instead of original sub
      oidc_required_fields = %w[user_id aud iss]
      unless decoded_token.present? && decoded_token.is_a?(Hash) && decoded_token.keys.to_set.superset?(oidc_required_fields.to_set)
        raise FailedAuthentication, "Error validating #{service_name} ID token: Missing some or all required fields (got #{decoded_token.keys.join(", ")}, expected #{oidc_required_fields.join(", ")})"
      end
    end

    def validate_id_token!(_id_token, decoded_token)
      raise FailedAuthentication, "Error validating ID token with Facebook: token is not valid" unless
        decoded_token["user_id"] && decoded_token["aud"] && decoded_token["iss"]
    end

    def remote_user_id_from_oidc(decoded_token, _user_atts = {})
      decoded_token["user_id"]
    end

    def extract_oidc_user_atts(decoded_token)
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

    def remote_user_id(decoded_token, user_atts = {})
      decoded_token["user_id"]
    end

    def validate_token!(_input_token, decoded_token)
      raise FailedAuthentication, "Error validating access_token with Facebook: token is not valid" unless
        decoded_token["is_valid"] && decoded_token["user_id"]
    end

    def extract_user_atts(access_token, decoded_token)
      fields_data = JSON.parse(get("/#{remote_user_id(decoded_token)}", query: {fields: "email,id,first_name,last_name,short_name,name", access_token: access_token}).body)
      raise FailedAuthentication, "Error validating access_token with Facebook: #{fields_data.dig("data", "error")}" if
        fields_data.dig("data", "error")

      unless fields_data.present? && fields_data.is_a?(Hash) && fields_data.keys.to_set.superset?(expected_fields_from_get_fields.to_set)
        raise FailedAuthentication, "Error validating #{service_name} access_token: Missing some or all user fields (got #{fields_data.keys.join(", ")}, " \
          "expected #{expected_fields_from_get_fields.join(", ")})"
      end

      {
        facebook_user_id: fields_data["id"],
        email: fields_data["email"],
        first_name: fields_data["first_name"],
        last_name: fields_data["last_name"],
        short_name: fields_data["short_name"],
        name: fields_data["name"]
      }.with_indifferent_access
    end
  end

  class FailedAuthentication < BaseAuthService::FailedAuthentication
  end
end

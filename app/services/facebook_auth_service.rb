# frozen_string_literal: true

class FacebookAuthService < BaseAuthService
  BASE_URI = "https://graph.facebook.com"
  base_uri BASE_URI

  class << self
    private

    def generate_appsecret_proof(access_token)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), ENV.fetch("FACEBOOK_APP_SECRET"), access_token)
    end

    def expected_fields
      %w[user_id]
    end

    def expected_fields_from_get_fields
      %w[id email]
    end

    def decode_token(input_token)
      app_access_token = "#{ENV.fetch("FACEBOOK_APP_ID")}|#{ENV.fetch("FACEBOOK_APP_SECRET")}"
      response = get("/debug_token", query: {
        input_token: input_token,
        access_token: app_access_token,
        appsecret_proof: generate_appsecret_proof(app_access_token)
      }).body
      decoded_token = JSON.parse(response)
      raise FailedAuthentication, "Error validating access_token with Facebook: #{decoded_token.dig("data", "error")}" if decoded_token.dig("data", "error")
      raise FailedAuthentication, "Error decoding access_token with Facebook (raw response is #{response.inspect})" unless decoded_token.is_a?(Hash) && decoded_token["data"]
      decoded_token["data"]
    end

    def remote_user_id(decoded_token, user_atts = {})
      decoded_token["user_id"]
    end

    def validate_token!(_input_token, decoded_token)
      raise FailedAuthentication, "Error validating access_token with Facebook: token is not valid" unless
        decoded_token["is_valid"] && decoded_token["user_id"]
    end

    def extract_user_atts(access_token, decoded_token)
      fields_data = JSON.parse(get("/#{remote_user_id(decoded_token)}", query: {
        fields: "email,id,first_name,last_name,short_name,name",
        access_token: access_token,
        appsecret_proof: generate_appsecret_proof(access_token)
      }).body)
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

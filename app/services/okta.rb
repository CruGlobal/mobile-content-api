# frozen_string_literal: true

class Okta
  include HTTParty
  LEEWAY = 0
  base_uri ENV.fetch("OKTA_SERVER_URL")

  class << self
    def find_user_by_access_token(access_token)
      validate_access_token_decode!(access_token)
      info = fetch_account_profile(access_token)
      unless info[:sso_guid]
        raise Okta::FailedAuthentication,
          "Access Token does not include sso guid, make sure login scope includes profile"
      end
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

    def validate_access_token_decode!(access_token)
      payload = JWT.decode(access_token, nil, false).first
      if payload["exp"] < LEEWAY.seconds.ago.to_i
        raise Okta::FailedAuthentication, "Expired access_token."
      end
      unless payload["cid"].in?(ENV["OKTA_SERVER_AUDIENCE"].split(","))
        raise Okta::FailedAuthentication, "Invalid access_token cid."
      end
      unless payload["iss"] == ENV["OKTA_SERVER_PATH"]
        raise Okta::FailedAuthentication,
          "Invalid issuer. Expected #{ENV["OKTA_SERVER_PATH"]}, received #{payload["iss"]}"
      end
    end

    def transform_jwt_payload(payload)
      {
        email: payload["email"],
        first_name: payload["given_name"],
        last_name: payload["family_name"],
        sso_guid: payload["ssoguid"]
      }.with_indifferent_access
    end

    def fetch_account_profile(access_token)
      path = "/oauth2/v1/userinfo"
      response = get(path, Authorization: "Bearer #{access_token}")
      raise Okta::FailedAuthentication, "Error validating access_token with Okta" if response.code != 200
      transform_jwt_payload(JSON.parse(response.body))
    end
  end

  class FailedAuthentication < StandardError
  end
end

# frozen_string_literal: true

class OktaAuthService < BaseAuthService
  LEEWAY = 0
  base_uri ENV.fetch("OKTA_SERVER_URL")

  class << self
    private

    def decode_token(access_token)
      JWT.decode(access_token, nil, false).first
    end

    def primary_key
      :sso_guid
    end

    def expected_fields
      %w[exp cid iss]
    end

    def validate_token!(_access_token, decoded_token)
      if decoded_token["exp"] < LEEWAY.seconds.ago.to_i
        raise self::FailedAuthentication, "Expired access_token."
      end
      unless decoded_token["cid"].in?(ENV["OKTA_SERVER_AUDIENCE"].split(","))
        raise self::FailedAuthentication, "Invalid access_token cid."
      end
      unless decoded_token["iss"] == ENV["OKTA_SERVER_PATH"]
        raise self::FailedAuthentication, "Invalid issuer. Expected #{ENV["OKTA_SERVER_PATH"]}, received #{decoded_token["iss"]}"
      end
    end

    def remote_user_id(decoded_token, user_atts = {})
      user_atts[primary_key]
    end

    def extract_user_atts(access_token, _decoded_token)
      path = "/oauth2/v1/userinfo"
      response = get(path, headers: {Authorization: "Bearer #{access_token}"})
      raise self::FailedAuthentication, "Error validating access_token with Okta" if response.code != 200
      userinfo_payload = JSON.parse(response.body)
      unless userinfo_payload["ssoguid"]
        raise self::FailedAuthentication, "Access Token does not include sso guid, make sure login scope includes profile"
      end

      {
        email: userinfo_payload["email"],
        first_name: userinfo_payload["given_name"],
        last_name: userinfo_payload["family_name"],
        name: userinfo_payload["name"],
        sso_guid: userinfo_payload["ssoguid"],
        gr_master_person_id: userinfo_payload["grMasterPersonId"]
      }.with_indifferent_access
    end

    def json_errors(code, detail)
      {errors:
        [
          {
            code: code,
            detail: detail
          }
        ]}
    end
  end
end

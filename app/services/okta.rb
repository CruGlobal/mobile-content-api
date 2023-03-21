# frozen_string_literal: true

class Okta < AuthServiceBase
  LEEWAY = 0
  base_uri ENV.fetch("OKTA_SERVER_URL")

  class << self
    private

    def decode_token
      JWT.decode(access_token, nil, false).first
    end

    def primary_key
      :sso_guid
    end

    def expected_fields
      %w[exp cid iss sso_guid email first_name last_name]
    end

    def validate_token!(_access_token, decoded_token)
      if decoded_token["exp"] < LEEWAY.seconds.ago.to_i
        raise FailedAuthentication, "Expired access_token."
      end
      unless decoded_token["cid"].in?(ENV["OKTA_SERVER_AUDIENCE"].split(","))
        raise FailedAuthentication, "Invalid access_token cid."
      end
      unless decoded_token["iss"] == ENV["OKTA_SERVER_PATH"]
        raise FailedAuthentication, "Invalid issuer. Expected #{ENV["OKTA_SERVER_PATH"]}, received #{decoded_token["iss"]}"
      end

      unless decoded_token[:sso_guid]
        raise FailedAuthentication, "Access Token does not include sso guid, make sure login scope includes profile"
      end
    end

    def remote_user_id(decoded_token)
      decoded_token[:sso_guid]
    end

    def extract_user_atts(access_token, _decoded_token)
      path = "/oauth2/v1/userinfo"
      response = get(path, headers: {Authorization: "Bearer #{access_token}"})
      raise FailedAuthentication, "Error validating access_token with Okta" if response.code != 200
      userinfo_payload = JSON.parse(response.body)

      {
        email: userinfo_payload["email"],
        first_name: userinfo_payload["given_name"],
        last_name: userinfo_payload["family_name"],
        sso_guid: userinfo_payload["ssoguid"],
        gr_master_person_id: userinfo_payload["grMasterPersonId"]
      }.with_indifferent_access
    end
  end
end

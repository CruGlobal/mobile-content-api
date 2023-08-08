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

    def remote_user_id(decoded_token)
      # noop since remote_user_id for okta is ssoguid given in the userinfo call
    end

    # reimplement setup_user to search on sso_guid (from user_atts) instead of using remote_user_id
    def setup_user(remote_user_id, user_atts)
      message = ""
      create_user = user_atts["create_user"]
      user = User.where(primary_key => user_atts[primary_key])

      if create_user == true
        if user.empty?
          user = User.new(primary_key => user_atts[primary_key])
          user.update!(user_atts)
        else
          message = "User account already exists."
        end
      elsif create_user == false
        if user.empty?
          message = "User account not found."
        else
          user = User.new(primary_key => user_atts[primary_key])
          user.update!(user_atts)
        end
      elsif create_user.nil?
        user = User.where(primary_key => user_atts[primary_key]).first_or_initialize
        user.update!(user_atts)
      end

      json = {}
      json = if message == "User account not found."
        json_errors("user_not_found", "User account not found.")
      elsif message == "User account already exists."
        json_errors("user_already_exists", "User account already exists.")
      end

      json.blank? ? user : json
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

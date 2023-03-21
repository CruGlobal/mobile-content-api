# frozen_string_literal: true

class GoogleAuth < AuthServiceBase
  include HTTParty

  class << self

    def find_user_by_access_token(access_token)
      super
    rescue Google::Auth::IDTokens::ExpiredTokenError => e
      raise self::FailedAuthentication, e.message
    end
    private

    def service_name
      "google"
    end

    def expected_fields
      %w[sub email given_name family_name]
    end

    # no easy way to get decoded token without validation with the google library, so this will return it with validation,
    # that's ok in the execution flow, if it raises an exception it will be caught and returned in AuthServiceBase
    def decode_token(access_token)
      Google::Auth::IDTokens.verify_oidc access_token, aud: ENV.fetch("GOOGLE_APP_ID")
    end

    def validate_token!(access_token, _decode_token)
      decode_token(access_token)
    end

    def remote_user_id(decoded_token)
      decoded_token["sub"]
    end

    def extract_user_atts(access_token, decoded_token)
      {
        google_user_id: remote_user_id(decoded_token),
        email: decoded_token["email"],
        first_name: decoded_token["given_name"],
        last_name: decoded_token["family_name"]
      }.with_indifferent_access
    end
  end

  class FailedAuthentication < AuthServiceBase::FailedAuthentication
  end
end

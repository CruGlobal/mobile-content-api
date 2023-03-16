# frozen_string_literal: true

class GoogleAuth
  include HTTParty

  class << self
    def find_user_by_access_token(access_token)
      info = validate_and_extract_token(access_token)
      unless info.present? && info.is_a?(Hash) && info.keys.to_set.superset?(%w[sub email given_name family_name].to_set)
        raise GoogleAuth::FailedAuthentication, "Error validating google access_token"
      end
      attributes = transform_fields(info)
      find_and_update_user(attributes) || create_user(attributes)
    rescue Google::Auth::IDTokens::VerificationError => e
      raise GoogleAuth::FailedAuthentication, e.message
    end

    private

    def find_and_update_user(user_info)
      user = User.find_by(google_user_id: user_info[:google_user_id])
      return nil unless user
      user.update(user_info)
      user
    end

    def create_user(user_info)
      User.create!(user_info)
    end

    def validate_and_extract_token(access_token)
      Google::Auth::IDTokens.verify_oidc access_token, aud: ENV.fetch("GOOGLE_APP_ID")
    end

    def transform_fields(fields)
      {
        google_user_id: fields["sub"],
        email: fields["email"],
        first_name: fields["given_name"],
        last_name: fields["family_name"],
      }.with_indifferent_access
    end

    def fetch_account_profile(info, user_id)
      transform_fields(data)
    end
  end

  class FailedAuthentication < StandardError
  end
end

# frozen_string_literal: true

class AppleAuthService < AuthServiceBase
  class << self
    def find_user_by_token(apple_id_token, apple_given_name = nil, apple_family_name = nil)
      decoded_token = decode_token(apple_id_token)
      validate_token!(apple_id_token, decoded_token)
      validate_expected_fields!(decoded_token)

      apple_id_token = remote_user_id(decoded_token)
      user_atts = extract_user_atts(apple_id_token, decoded_token, apple_id_token)
      user_atts["first_name"] = apple_given_name if apple_given_name.present?
      user_atts["last_name"] = apple_family_name if apple_family_name.present?
      setup_user(apple_id_token, user_atts)
    rescue JSON::ParserError => e
      raise FailedAuthentication, e.message
    rescue JWT::DecodeError => e
      raise FailedAuthentication, e.message
    rescue JWT::ExpiredSignature => e
      raise FailedAuthentication, e.message
    rescue AppleAuth::Conditions::JWTValidationError => e
      raise FailedAuthentication, e.message
    end

    private

    def primary_key
      :"#{service_name}_id_token"
    end

    def expected_fields
      %w[sub email iss aud]
    end

    def decode_token(apple_id_token)
      AppleAuth::JWTDecoder.new(apple_id_token).call
    end

    def validate_token!(apple_id_token, decoded_token)
      raise FailedAuthentication, "Sub is missing from payload" unless decoded_token["sub"]
      AppleAuth::UserIdentity.new(decoded_token["sub"], apple_id_token).validate!
    end

    def remote_user_id(decoded_token)
      decoded_token["sub"]
    end

    def extract_user_atts(_apple_id_token, decoded_token, remote_user_id)
      {
        apple_id_token: remote_user_id,
        email: decoded_token["email"]
      }.with_indifferent_access
    end
  end

  class FailedAuthentication < AuthServiceBase::FailedAuthentication
  end
end

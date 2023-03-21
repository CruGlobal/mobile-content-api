# frozen_string_literal: true

class AuthServiceBase
  include HTTParty

  class << self
    def find_user_by_access_token(access_token)
      decoded_token = decode_token(access_token)
      validate_token!(access_token, decoded_token)
      validate_expected_fields!(decoded_token)

      user_atts = extract_user_atts(access_token, decoded_token)
      setup_user(remote_user_id(decoded_token), user_atts)
    rescue JSON::ParserError => e
      raise self::FailedAuthentication, e.message
    rescue JWT::DecodeError => e
      raise self::FailedAuthentication, e.message
    rescue JWT::ExpiredSignature => e
      raise self::FailedAuthentication, e.message
    end

    private

    def validate_expected_fields!(decoded_token)
      unless decoded_token.present? && decoded_token.is_a?(Hash) && decoded_token.keys.to_set.superset?(expected_fields.to_set)
        raise FailedAuthentication, "Error validating #{service_name} access_token: Missing some or all user fields (got #{decoded_token.keys.join(", ")}, expected #{expected_fields.join(", ")})"
      end
    end

    def setup_user(remote_user_id, user_atts)
      user = User.where(primary_key => remote_user_id).first_or_initialize
      user.update!(user_atts)
      user
    end

    def service_name
      self.name.downcase
    end

    def primary_key
      :"#{service_name}_user_id"
    end

    def decode_token(access_token)
      raise("extending class should implement decode_token(access_token)")
    end

    def expected_fields
      raise("extending class should implement expected_fields (array of strings)")
    end

    def remote_user_id(decoded_token)
      raise("extending class should implement remote_user_id(decoded_token)")
    end

    # some auth methods use libraries that operate on access_token, other ones we operate on the decoded_token
    def validate_token!(access_token, decoded_token)
      raise("extending class should implement validate_token!(access_token, decoded_token)")
    end

    def extract_user_atts(access_token, decoded_token)
      raise("extending class should implement extract_user_atts(access_token, decoded_token)")
    end
  end

  class FailedAuthentication < StandardError
  end
end

# frozen_string_literal: true

class Apple
  include HTTParty

  class << self
    def find_user_by_access_token(access_token, apple_given_name = nil, apple_family_name = nil)
      info = validate_and_extract_token(access_token)
      puts info.inspect
      unless info.present? && info.is_a?(Hash) && info.keys.to_set.superset?(%w[sub email].to_set)
        raise Apple::FailedAuthentication, "Error validating apple access_token"
      end

      attributes = transform_fields(info)
      attributes["first_name"] = apple_given_name if apple_given_name.present?
      attributes["last_name"] = apple_family_name if apple_family_name.present?

      user = User.where(apple_user_id: attributes[:apple_user_id]).first_or_initialize
      user.update!(attributes)
      user
    rescue JSON::ParserError => e
      raise Apple::FailedAuthentication, e.message
    rescue JWT::ExpiredSignature => e
      raise Apple::FailedAuthentication, e.message
    end

    private

    def validate_and_extract_token(access_token)
      AppleAuth::JWTDecoder.new(access_token).call
    end

    def transform_fields(fields)
      {
        apple_user_id: fields["sub"],
        email: fields["email"]
      }.with_indifferent_access
    end
  end

  class FailedAuthentication < StandardError
  end
end

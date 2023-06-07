# frozen_string_literal: true

class AppleAuthService < BaseAuthService
  class << self
    def find_user_by_refresh_token(refresh_token)
      apple_id_client.refresh_token = refresh_token
      find_user
    end

    def find_user_by_auth_code(apple_auth_code, apple_given_name = nil, apple_family_name = nil)
      apple_id_client.authorization_code = apple_auth_code
      [find_user(apple_given_name, apple_family_name), @response.refresh_token]
    end

    def find_user(apple_given_name = nil, apple_family_name = nil)
      @response = apple_id_client.access_token!
      id_token = @response.id_token

      validate_expected_fields!(id_token.raw_attributes)

      id_token.verify!(
        client: apple_id_client,
        access_token: @response.access_token
      )

      user_atts = {apple_user_id: id_token.sub, email: id_token.email}
      user_atts["first_name"] = apple_given_name if apple_given_name.present?
      user_atts["last_name"] = apple_family_name if apple_family_name.present?
      setup_user(id_token.sub, user_atts)
    rescue JSON::ParserError => e
      raise self::FailedAuthentication, "#{e.class.name}: #{e.message}"
    rescue AppleID::IdToken::VerificationFailed => e
      raise self::FailedAuthentication, "#{e.class.name}: #{e.message}"
    rescue AppleID::Client::Error => e
      apple_key_details = if Rails.env.development? || Rails.env.staging?
        apple_envs = ENV.find_all { |k, v| k["APPLE"] }.collect { |k, v| "#{k}=#{(k == "APPLE_PRIVATE_KEY") ? "..." + ENV["APPLE_PRIVATE_KEY"].split("\n")[4].last(4) : v}" }.join(", ")
        " (#{apple_envs})"
      else
        ""
      end
      raise self::FailedAuthentication, "#{e.class.name}: #{e.message}#{apple_key_details}"
    end

    private

    def expected_fields
      %w[sub email iss aud]
    end

    def apple_id_client
      AppleID.debug! if Rails.env.staging?

      @apple_id_client ||= AppleID::Client.new(
        identifier: ENV.fetch("APPLE_CLIENT_ID"),
        team_id: ENV.fetch("APPLE_TEAM_ID"),
        key_id: ENV.fetch("APPLE_KEY_ID"),
        private_key: OpenSSL::PKey::EC.new(ENV.fetch("APPLE_PRIVATE_KEY")),
        redirect_uri: ENV.fetch("APPLE_REDIRECT_URI")
      )
    end
  end

  class FailedAuthentication < BaseAuthService::FailedAuthentication
  end
end

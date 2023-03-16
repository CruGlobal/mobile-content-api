# frozen_string_literal: true

class Facebook
  BASE_URI = "https://graph.facebook.com"
  include HTTParty
  base_uri BASE_URI

  class << self
    def find_user_by_access_token(access_token)
      user_id = validate_and_extract_user_id(access_token)
      info = fetch_account_profile(access_token, user_id)
      find_and_update_user(info) || create_user(info)
    rescue JSON::ParserError => e
      raise Facebook::FailedAuthentication, e.message
    end

    private

    def find_and_update_user(user_info)
      user = User.find_by(facebook_user_id: user_info[:facebook_user_id])
      return nil unless user
      user.update(user_info)
      user
    end

    def create_user(user_info)
      User.create!(user_info)
    end

    def validate_and_extract_user_id(access_token)
      data = JSON.parse(get("/debug_token", query: {input_token: access_token, access_token: "#{ENV.fetch("FACEBOOK_APP_ID")}|#{ENV.fetch("FACEBOOK_APP_SECRET")}"}))
      raise Facebook::FailedAuthentication, "Error validating access_token with Facebook: #{data.dig("data", "error")}" if data.dig("data", "error")
      raise Facebook::FailedAuthentication, "Error validating access_token with Facebook: no facebook user id returned" unless data["data"] && data["data"]["is_valid"] && data["data"]["user_id"]

      data["data"]["user_id"]
    end

    def fetch_account_profile(access_token, user_id)
      data = JSON.parse(get("/#{user_id}", query: {fields: "email,id,first_name,last_name,short_name", access_token: access_token}))
      raise Facebook::FailedAuthentication, "Error validating access_token with Facebook: #{data.dig("data", "error")}" if
        data.dig("data", "error")
      raise Facebook::FailedAuthentication, "Error validating access_token with Facebook: Missing some or all user fields" unless
        data.keys.to_set.superset?(%w[id first_name last_name email short_name].to_set)

      {
        facebook_user_id: data["id"],
        email: data["email"],
        first_name: data["first_name"],
        last_name: data["last_name"],
        short_name: data["short_name"]
      }.with_indifferent_access
    end
  end

  class FailedAuthentication < StandardError
  end
end

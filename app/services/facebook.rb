# frozen_string_literal: true

class Facebook
  include HTTParty

  class << self
    def find_user_by_access_token(access_token)
      user_id = validate_and_extract_user_id(access_token)
      info = fetch_account_profile(access_token, user_id)
      user = find_and_update_user(info) || create_user(info)
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
      unless /^[0-9a-zA-Z]+$/.match?(access_token)
        raise Facebook::FailedAuthentication, "Invalid token format, it should be alpha-numerical"
      end

      url = "https://graph.facebook.com/debug_token?input_token=#{access_token}&access_token=#{ENV.fetch("FACEBOOK_APP_ID")}|#{ENV.fetch("FACEBOOK_APP_SECRET")}"
      data = JSON.parse(get(url))
      raise Facebook::FailedAuthentication, "Error validating access_token with Facebook: #{data["data"]["error"]}" if data["data"] && data["data"]["error"]
      raise Facebook::FailedAuthentication, "Error validating access_token with Facebook: no facebook user id returned" unless data["data"] && data["data"]["is_valid"] && data["data"]["user_id"]

      data["data"]["user_id"]
    end

    def transform_fields(fields)
      {
        facebook_user_id: fields["id"],
        email: fields["email"],
        first_name: fields["first_name"],
        last_name: fields["last_name"],
        short_name: fields["short_name"]
      }.with_indifferent_access
    end

    def fetch_account_profile(access_token, user_id)
      url = "https://graph.facebook.com/#{user_id}?fields=email,id,first_name,last_name,short_name&access_token=#{access_token}"
      data = JSON.parse(get(url))
      raise Facebook::FailedAuthentication, "Error validating access_token with Facebook: #{data["data"]["error"]}" if data["data"] && data["data"]["error"]
      raise Facebook::FailedAuthentication, "Error validating access_token with Facebook: Missing some or all user fields" unless data.keys.to_set.superset?(%w[id first_name last_name email short_name].to_set)

      transform_fields(data)
    end
  end

  class FailedAuthentication < StandardError
  end
end

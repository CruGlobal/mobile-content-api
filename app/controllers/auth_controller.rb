# frozen_string_literal: true

class AuthController < ApplicationController
  def create
    token = if data_attrs[:okta_access_token]
      auth_with_okta
    elsif data_attrs[:facebook_access_token]
      auth_with_facebook
    else
      auth_with_code
    end
    render json: token, status: :created if token
  end

  private

  def render_bad_request(message)
    code = AccessCode.new
    code.errors.add(:code, message)

    render_error(code, :bad_request)
  end

  def auth_with_code
    AccessCode.validate(data_attrs[:code])
    AuthToken.new
  rescue AccessCode::FailedAuthentication => e
    render_bad_request e.message
    nil
  end

  def auth_with_okta
    user = Okta.find_user_by_access_token(data_attrs[:okta_access_token])
    AuthToken.new(user: user)
  rescue Okta::FailedAuthentication => e
    render_bad_request e.message
    nil
  end

  def auth_with_facebook
    return unless /^[0-9a-zA-Z]/.match?(data_attrs[:facebook_access_token])
    url = "https://graph.facebook.com/debug_token?input_token=#{data_attrs[:facebook_access_token]}&access_token=#{ENV.fetch("FACEBOOK_APP_ID")}|#{ENV.fetch("FACEBOOK_APP_SECRET")}"

    data = JSON.parse(Net::HTTP.get(URI(url)))
    (render_bad_request(data["data"]["error"]) and return) if data["data"] && data["data"]["error"]
    (render_bad_request("facebook token is not valid") and return) unless data["data"] && data["data"]["is_valid"] && data["data"]["user_id"]

    user_id = data["data"]["user_id"]
    url = "https://graph.facebook.com/#{user_id}?fields=email,id,first_name,last_name,short_name&access_token=#{data_attrs[:facebook_access_token]}"
    data = JSON.parse(Net::HTTP.get(URI(url)))
    (render_bad_request(data["data"]["error"]) and return) if data["data"] && data["data"]["error"]

    user = User.where(facebook_user_id: data["id"]).first_or_create
    user.update!(email: data["email"], first_name: data["first_name"], last_name: data["last_name"], short_name: data["short_name"])
    AuthToken.new(user: user)
  end
end

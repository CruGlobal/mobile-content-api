# frozen_string_literal: true

class AuthController < ApplicationController
  def create
    token = if data_attrs[:okta_access_token]
      auth_with_okta
    elsif data_attrs[:facebook_access_token]
      auth_with_facebook
    elsif data_attrs[:google_access_token]
      auth_with_google
    elsif data_attrs[:apple_access_token]
      auth_with_apple
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
    user = Facebook.find_user_by_access_token(data_attrs[:facebook_access_token])
    AuthToken.new(user: user)
  rescue Facebook::FailedAuthentication => e
    render_bad_request e.message
    nil
  end

  def auth_with_google
    user = GoogleAuth.find_user_by_access_token(data_attrs[:google_access_token])
    AuthToken.new(user: user)
  rescue GoogleAuth::FailedAuthentication => e
    render_bad_request e.message
    nil
  end

  def auth_with_apple
    user = Apple.find_user_by_access_token(data_attrs[:apple_access_token], data_attrs[:apple_given_name], data_attrs[:apple_family_name])
    AuthToken.new(user: user)
  rescue Apple::FailedAuthentication => e
    render_bad_request e.message
    nil
  end
end

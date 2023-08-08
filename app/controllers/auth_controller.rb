# frozen_string_literal: true

class AuthController < ApplicationController
  THIRD_PARTY_AUTH_METHODS = [:okta, :facebook, :google, :apple_auth, :apple_refresh]

  def create
    message = []
    method = THIRD_PARTY_AUTH_METHODS.detect { |method|
      data_attrs[:"#{method}_access_token"] || data_attrs[:"#{method}_id_token"] ||
        data_attrs["#{method}_code"] || data_attrs["#{method}_token"]
    }
    token = case method
    when :apple_auth
      # special case for apple, which has given and family name passed in
      user, message, apple_refresh_token = AppleAuthService.find_user_by_auth_code(data_attrs[:apple_auth_code], data_attrs[:apple_given_name], data_attrs[:apple_family_name], data_attrs[:create_user])
      AuthToken.new(user: user, apple_refresh_token: apple_refresh_token)
    when :apple_refresh
      user = AppleAuthService.find_user_by_refresh_token(data_attrs[:apple_refresh_token])
      AuthToken.new(user: user)
    when :google
      user, message = GoogleAuthService.find_user_by_token(data_attrs[:google_id_token], data_attrs[:create_user])
      AuthToken.new(user: user)
    when :okta, :facebook
      user, message = "::#{method.to_s.capitalize}AuthService".constantize.find_user_by_token(data_attrs[:"#{method}_access_token"], data_attrs[:create_user])
      AuthToken.new(user: user)
    else
      AccessCode.validate(data_attrs[:code])
      AuthToken.new
    end

    if message.blank?
      render json: token, status: :created if token
    else
      json = if message == "User account not found."
        json_errors("user_not_found", "User account not found.")
      else
        json_errors("user_already_exists", "User account already exists.")
      end
      render json: json, status: :bad_request
    end
  rescue BaseAuthService::FailedAuthentication => e
    render_bad_request e.message
    nil
  rescue AccessCode::FailedAuthentication => e
    render_bad_request e.message
    nil
  end

  private

  def render_bad_request(message)
    code = AccessCode.new
    code.errors.add(:code, message)

    render_error(code, :bad_request)
  end

  def json_errors(code, detail)
    {errors:
      [
        {
          code: code,
          detail: detail
        }
      ]}
  end
end

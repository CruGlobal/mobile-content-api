# frozen_string_literal: true

class AuthController < ApplicationController
  def create
    if data_attrs[:apple_auth_code].present?
      # special case for apple, which has given and family name passed in
      user, apple_refresh_token = AppleAuthService.find_user_by_auth_code(data_attrs[:apple_auth_code], data_attrs[:apple_given_name], data_attrs[:apple_family_name],
        data_attrs[:apple_name], data_attrs[:create_user])
      # make the token here since it's a special case
      token = AuthToken.new(user: user, apple_refresh_token: apple_refresh_token)
    elsif data_attrs[:apple_refresh_token].present?
      user = AppleAuthService.find_user_by_refresh_token(data_attrs[:apple_refresh_token], data_attrs[:create_user])
    elsif data_attrs[:google_id_token].present?
      user = GoogleAuthService.find_user_by_token(data_attrs[:google_id_token], data_attrs[:create_user])
    elsif data_attrs[:okta_access_token].present?
      user = OktaAuthService.find_user_by_token(data_attrs[:okta_access_token], data_attrs[:create_user])
    elsif data_attrs[:facebook_access_token].present?
      user = FacebookAuthService.find_user_by_token(data_attrs[:facebook_access_token], data_attrs[:create_user])
    elsif data_attrs[:facebook_id_token].present?
      user = FacebookOidcAuthService.find_user_by_token(data_attrs[:facebook_id_token], data_attrs[:create_user])
    else
      AccessCode.validate(data_attrs[:code])
      user = nil
    end

    token ||= AuthToken.new(user: user)

    render json: token, status: :created if token
  rescue UserAlreadyExist::Error => e
    render json: json_errors("user_already_exists", e.message), status: :bad_request
    nil
  rescue UserNotFound::Error => e
    render json: json_errors("user_not_found", e.message), status: :bad_request
    nil
  rescue BaseAuthService::FailedAuthentication => e
    # TODO: change this to an unauthorized status once the Android app has been updated
    render json: json_errors("invalid_token", e.message), status: :bad_request
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

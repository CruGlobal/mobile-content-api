# frozen_string_literal: true

class AuthController < ApplicationController
  THIRD_PARTY_AUTH_METHODS = [:okta, :facebook, :google, :apple]

  def create
    method = THIRD_PARTY_AUTH_METHODS.detect { |method| data_attrs[:"#{method}_access_token"] || data_attrs[:"#{method}_id_token"] }
    token = case method
    when :apple
      # special case for apple, which has given and family name passed in
      user = AppleAuthService.find_user_by_token(data_attrs[:apple_id_token], data_attrs[:apple_given_name], data_attrs[:apple_family_name])
      AuthToken.new(user: user)
    when :google
      user = GoogleAuthService.find_user_by_token(data_attrs[:google_id_token])
      AuthToken.new(user: user)
    when :okta, :facebook
      user = "::#{method.to_s.capitalize}AuthService".constantize.find_user_by_token(data_attrs[:"#{method}_access_token"])
      AuthToken.new(user: user)
    else
      AccessCode.validate(data_attrs[:code])
      AuthToken.new
    end

    render json: token, status: :created if token
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
end

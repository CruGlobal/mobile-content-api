# frozen_string_literal: true

class AuthController < ApplicationController
  THIRD_PARTY_AUTH_METHODS = {
    okta: Okta,
    facebook: Facebook,
    google: GoogleAuth, # the google gem uses Google namespace
    apple: Apple
  }

  def create
    method = THIRD_PARTY_AUTH_METHODS.keys.detect { |method| data_attrs[:"#{method}_access_token"] }
    token = case method
    when :apple
      # special case for apple, which has given and family name passed in
      user = Apple.find_user_by_token(data_attrs[:apple_access_token], data_attrs[:apple_given_name], data_attrs[:apple_family_name])
      AuthToken.new(user: user)
    when :okta, :facebook, :google
      user = THIRD_PARTY_AUTH_METHODS[method].find_user_by_token(data_attrs[:"#{method}_access_token"])
      AuthToken.new(user: user)
    else
      AccessCode.validate(data_attrs[:code])
      AuthToken.new
    end

    render json: token, status: :created if token
  rescue AuthServiceBase::FailedAuthentication => e
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

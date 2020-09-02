# frozen_string_literal: true

class AuthController < ApplicationController
  def create
    token = data_attrs[:okta_id_token] ? auth_with_okta : auth_with_code
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
    user = Okta.find_user_by_id_token(data_attrs[:okta_id_token])
    AuthToken.new(user: user)
  rescue Okta::FailedAuthentication => e
    render_bad_request e.message
    nil
  end
end

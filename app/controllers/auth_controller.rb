# frozen_string_literal: true

class AuthController < ApplicationController
  def create
    create_auth_token
  end

  private

  def create_auth_token
    AuthToken.create!(access_code: access_code)
    render plain: 'OK', status: :created
  rescue
    render plain: 'Access code not found', status: :bad_request
  end

  def access_code
    AccessCode.find_by(code: params[:code])
  end
end

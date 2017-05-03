# frozen_string_literal: true

class AuthController < ApplicationController
  def create
    create_auth_token
  end

  private

  def create_auth_token
    code = AccessCode.find_by(code: params[:data][:attributes][:code])

    if code.nil?
      render plain: 'Access code not found', status: :bad_request
      return
    end

    if expired(code)
      render plain: 'Access code expired', status: :bad_request
      return
    end

    token = AuthToken.create!(access_code: code)
    render json: token, status: :created
  end

  def expired(code)
    code.expiration < DateTime.now.utc - 7.days
  end
end

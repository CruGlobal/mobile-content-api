# frozen_string_literal: true

class AuthController < ApplicationController
  def create
    create_auth_token
  end

  private

  def create_auth_token
    AuthToken.create_from_access_code!(AccessCode.find_by(code: params[:code]))
    render plain: 'OK', status: :created
  end
end

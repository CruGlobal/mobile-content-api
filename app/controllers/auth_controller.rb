# frozen_string_literal: true

class AuthController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    create_auth_token
  end

  private

  def create_auth_token
    head AuthToken.create_from_access_code!(AccessCode.find_by(code: params[:code]))
  end
end

# frozen_string_literal: true

class AuthController < ApplicationController
  protect_from_forgery with: :null_session

  def auth_token
    create
  end

  private

  def create
    head AuthToken.create_from_access_code!(AccessCode.find_by(code: params[:code]))
  end
end

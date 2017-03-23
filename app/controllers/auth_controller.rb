# frozen_string_literal: true

class AuthController < ApplicationController
  protect_from_forgery with: :null_session

  def auth_token
    submitted_code = params[:code]
    code_from_db = AccessCode.where(code: submitted_code)

    if code_from_db.empty?
      render json: 'Access code not valid.', status: 400
    else
      token = AuthToken.create(id: SecureRandom.uuid, access_code: code_from_db.first, token: SecureRandom.uuid)
      render json: token.token
    end
  end
end

# frozen_string_literal: true

class AuthController < ApplicationController
  protect_from_forgery with: :null_session

  def auth_token
    code_from_db = AccessCode.find_by(code: params[:code])

    if code_from_db.nil?
      render json: 'Access code not valid.', status: 400
    else
      token = AuthToken.create(id: SecureRandom.uuid, access_code: code_from_db, token: SecureRandom.uuid)
      render json: token.token
    end
  end
end

class AuthController < ApplicationController

  protect_from_forgery with: :null_session

  def getAuthToken

    submittedCode = params[:code]
    codeFromDb = AccessCode.where(code: submittedCode)

    if codeFromDb.empty?
      render json: "Access code not valid.", status: 400
    else
      token = AuthToken.create(id: SecureRandom.uuid, access_code: codeFromDb.first, token: SecureRandom.uuid)
      render json: token.token, status: 200
    end

  end

end
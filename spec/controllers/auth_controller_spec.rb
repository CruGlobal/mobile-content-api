# frozen_string_literal: true

require "rails_helper"

describe AuthController do
  before { Mime::Type.register "application/vnd.api+json", :json_api }

  let(:user) { FactoryBot.create(:user) }

  describe "POST create" do
    it "sets an HttpOnly auth cookie for a user-bearing token" do
      allow(OktaAuthService).to receive(:find_user_by_token).and_return(user)

      post :create, params: {data: {type: "auth-token", attributes: {okta_access_token: "tok"}}}

      expect(response).to have_http_status(:created)
      jwt = response.cookies["auth_token"]
      expect(jwt).to be_present
      expect(AuthToken.decode(jwt).first["user_id"]).to eq(user.id)
    end

    it "flags the auth cookie HttpOnly, Lax and not readable by JS" do
      allow(OktaAuthService).to receive(:find_user_by_token).and_return(user)

      post :create, params: {data: {type: "auth-token", attributes: {okta_access_token: "tok"}}}

      set_cookie = response.headers["Set-Cookie"]
      expect(set_cookie).to match(/auth_token=/)
      expect(set_cookie).to match(/HttpOnly/i)
      expect(set_cookie).to match(/SameSite=Lax/i)
    end

    it "does not set an auth cookie for a userless (access code) token" do
      code = AccessCode.create!(code: 654_321)

      post :create, params: {data: {type: "auth-token", attributes: {code: code.code}}}

      expect(response).to have_http_status(:created)
      expect(response.cookies["auth_token"]).to be_nil
    end
  end

  describe "GET me" do
    it "returns the current user when the cookie is valid" do
      cookies[:auth_token] = AuthToken.new(user: user).token

      get :me

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)["data"]
      expect(data["id"]).to eq(user.id)
      expect(data["email"]).to eq(user.email)
    end

    it "returns the current user when the Authorization header is valid" do
      request.headers["Authorization"] = AuthToken.new(user: user).token

      get :me

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["id"]).to eq(user.id)
    end

    it "is unauthorized when there is no session" do
      get :me

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE destroy" do
    it "clears the auth cookie" do
      request.cookies["auth_token"] = "existing"

      delete :destroy

      expect(response).to have_http_status(:no_content)
      expect(response.cookies["auth_token"]).to be_nil
    end
  end
end

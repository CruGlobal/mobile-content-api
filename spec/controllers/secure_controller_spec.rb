# frozen_string_literal: true

require "rails_helper"

describe SecureController do
  controller do
    def index
    end
  end

  let(:not_found_token) { "3240fa3f-d242-49e3-a03f-4d4ce68ea13d" }
  let(:expired_token) { "b0a0faef-2851-4b24-b53f-cf136ba22f78" }

  it "unauthorized if token is nil" do
    request.headers["Authorization"] = nil

    get :index

    expect(response).to have_http_status(:unauthorized)
  end

  it "unauthorized if token is not found" do
    request.headers["Authorization"] = not_found_token

    get :index

    expect(response).to have_http_status(:unauthorized)
  end

  it "unauthorized if token is expired" do
    request.headers["Authorization"] = expired_token
    allow(AuthToken).to(receive(:find_by).with(token: expired_token)
                          .and_return(AuthToken.new(expiration: DateTime.now.utc - 1.second)))

    get :index

    expect(response).to have_http_status(:unauthorized)
  end
end

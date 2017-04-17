# frozen_string_literal: true

require 'rails_helper'

describe AuthController do
  it 'creates a token if access code is valid' do
    expect(AuthToken).to receive(:create!)

    post :create, params: { code: 123_456 }

    expect(response).to have_http_status(:created)
  end

  it 'returns bad request a token if access code is invalid' do
    expect(AuthToken).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

    post :create, params: { code: 223_456 }

    expect(response).to have_http_status(:bad_request)
  end
end

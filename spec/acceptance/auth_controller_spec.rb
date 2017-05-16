# frozen_string_literal: true

require 'acceptance_helper'

resource 'Auth' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'
  let(:raw_post) { params.to_json }
  let(:valid_code) { 123_456 }

  post 'auth/' do
    it 'create a token with valid code' do
      do_request data: { type: :auth_token, attributes: { code: valid_code } }

      expect(status).to be(201)
    end

    it 'create a token with invalid code' do
      do_request data: { type: :auth_token, attributes: { code: 999_999 } }

      expect(status).to be(400)
    end

    it 'create a token with expired code' do
      allow(AccessCode).to(
        receive(:find_by).with(code: valid_code).and_return(AccessCode.new(expiration: DateTime.now.utc - 1.second))
      )

      do_request data: { type: :auth_token, attributes: { code: valid_code } }

      expect(status).to be(400)
    end
  end
end

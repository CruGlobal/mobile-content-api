# frozen_string_literal: true

require 'acceptance_helper'

resource 'Views' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }
  let(:authorization) do
    AuthToken.create!(access_code: AccessCode.find(1)).token
  end

  before do
    header 'Authorization', :authorization
  end

  post 'views/' do
    requires_authorization

    it 'add views' do
      do_request data: { type: :view, attributes: { resource_id: 1, quantity: 257 } }

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end

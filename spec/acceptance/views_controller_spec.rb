# frozen_string_literal: true

require 'acceptance_helper'

resource 'Views' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }

  post 'views/' do
    it 'does not allow unauthorized requests', document: false do
      header 'Authorization', nil

      do_request data: { type: :view, attributes: { resource_id: 1, quantity: 257 } }

      expect(status).to be(401)
    end

    it 'add views' do
      header 'Authorization', AuthToken.create(access_code: AccessCode.find(1)).token

      do_request data: { type: :view, attributes: { resource_id: 1, quantity: 257 } }

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end

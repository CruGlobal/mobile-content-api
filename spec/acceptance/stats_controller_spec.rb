# frozen_string_literal: true

require 'acceptance_helper'

resource 'Stats' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }

  post 'stats/' do
    header 'Authorization', AuthToken.create(access_code: AccessCode.find(1)).token

    it 'add stats' do
      do_request data: { type: :stat, attributes: { resource_id: 1, quantity: 257 } }

      expect(status).to be(201)
    end
  end
end

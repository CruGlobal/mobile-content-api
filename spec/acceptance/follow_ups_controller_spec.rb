# frozen_string_literal: true

require 'acceptance_helper'

resource 'Follow Ups' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'
  let(:raw_post) { params.to_json }

  post 'follow_ups/' do
    it 'create a subscriber' do
      do_request data: { type: :follow_up, attributes: { name: 'Billy Bob', email: 'bob@test.com', language_id: 2 } }

      expect(status).to be(204)
      expect(response_body['data']).to be_nil
    end

    it 'returns bad request if not valid data', document: false do
      do_request data: { type: :follow_up, attributes: { name: 'Billy Bob', language_id: 2 } }

      expect(status).to be(400)
      expect(JSON.parse(response_body)['errors'][0]['detail']).to(eq("can't be blank"))
    end
  end
end

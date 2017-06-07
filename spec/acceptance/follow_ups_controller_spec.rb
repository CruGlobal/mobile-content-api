# frozen_string_literal: true

require 'acceptance_helper'

resource 'Follow Ups' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'
  let(:raw_post) { params.to_json }
  let(:destination_id) { 123 }

  before do
    allow(Destination).to receive(:find).with(destination_id).and_return(Destination.new(id: destination_id))
  end

  post 'follow_ups/' do
    let(:data) do
      { type: :follow_up,
        attributes: { name: 'Billy Bob', email: 'bob@test.com', language_id: 2, destination_id: destination_id } }
    end

    it 'create a subscriber' do
      allow(RestClient).to receive(:post).and_return(instance_double(RestClient::Response, code: 201))

      do_request data: data

      expect(status).to be(204)
      expect(response_body['data']).to be_nil
    end

    it 'returns remote response code if request failed', document: false do
      allow(RestClient).to receive(:post).and_return(instance_double(RestClient::Response, code: 404))

      do_request data: data

      expect(status).to be(400)
      expect(JSON.parse(response_body)['errors'][0]['detail'])
        .to(eq("Received response code: 404 from destination: #{destination_id}"))
    end

    it 'returns bad request if missing data', document: false do
      do_request data: { type: :follow_up,
                         attributes: { name: 'Billy Bob', language_id: 2, destination_id: destination_id } }

      expect(status).to be(400)
      expect(JSON.parse(response_body)['errors'][0]['detail']).to(eq("can't be blank"))
    end
  end
end

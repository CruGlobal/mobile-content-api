# frozen_string_literal: true

require 'acceptance_helper'

resource 'Attributes' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'
  let(:raw_post) { params.to_json }
  let(:authorization) do
    AuthToken.create!(access_code: AccessCode.find(1)).token
  end

  post 'attributes/' do
    let(:data) { { type: :attribute, attributes: { key: 'foo', value: 'bar', resource_id: 1 } } }

    requires_authorization

    it 'create an Attribute' do
      do_request data: data

      expect(status).to be(204)
      expect(response_body).to be_empty
    end

    it 'sets location header', document: false do
      do_request data: data

      expect(response_headers['Location']).to match(%r{attributes\/\d+})
    end
  end

  put 'attributes/:id' do
    let(:id) { 1 }

    requires_authorization

    it 'update an Attribute' do
      do_request data: { type: :attribute, attributes: { key: 'foo', value: 'new value', resource_id: 1 } }

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end

  delete 'attributes/:id' do
    let(:id) { 1 }

    requires_authorization

    it 'delete an Attribute' do
      do_request

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end

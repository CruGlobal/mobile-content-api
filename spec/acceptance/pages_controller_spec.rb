# frozen_string_literal: true

require 'acceptance_helper'

resource 'Pages' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.create!(access_code: AccessCode.find(1)).token }

  before do
    header 'Authorization', :authorization
  end

  post 'pages' do
    let(:attrs) { { filename: 'test.xml', structure: :updated_structure, resource_id: 2, position: 1 } }

    requires_authorization

    it 'create page' do
      do_request data: { type: :page, attributes: attrs }

      expect(status).to eq(201)
      expect(response_body['data']).not_to be_nil
    end

    it 'sets location header', document: false do
      do_request data: { type: :page, attributes: attrs }

      expect(response_headers['Location']).to match(%r{pages\/\d+})
    end
  end

  put 'pages/:id' do
    let(:id) { 1 }
    let(:updated_structure) { '<?xml version="1.0" encoding="UTF-8" ?><page> new page </page>' }

    requires_authorization

    it 'edit page' do
      do_request data: { type: :page, attributes: { structure: :updated_structure } }

      expect(status).to eq(200)
      expect(response_body['data']).not_to be_nil
    end
  end
end

# frozen_string_literal: true

require 'acceptance_helper'

resource 'Pages' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }

  put 'pages/:id' do
    let(:id) { 1 }
    let(:updated_structure) { '<?xml version="1.0" encoding="UTF-8" ?><page> new page </page>' }

    it 'does not allow unauthorized requests', document: false do
      header 'Authorization', nil

      do_request data: { type: :page, attributes: { structure: :updated_structure } }

      expect(status).to eq(401)
    end

    it 'edit page' do
      header 'Authorization', AuthToken.create(access_code: AccessCode.find(1)).token

      do_request data: { type: :page, attributes: { structure: :updated_structure } }

      expect(status).to eq(200)
      expect(response_body['data']).to_not be_nil
    end
  end
end

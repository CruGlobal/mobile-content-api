# frozen_string_literal: true

require 'acceptance_helper'

resource 'CustomPages' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }
  let(:pages) { TestConstants::GodTools::Pages }
  let(:german_2) { TestConstants::GodTools::Translations::German2::ID }
  let(:structure) { '<custom>This is some custom xml for one translation</custom>' }
  let(:authorization) do
    AuthToken.create!(access_code: AccessCode.find(1)).token
  end

  before do
    header 'Authorization', :authorization
  end

  post 'custom_pages/' do
    requires_authorization

    context 'creating' do
      let(:attrs) { { translation_id: german_2, page_id: pages::Page4::ID, structure: structure } }

      it 'create a custom page' do
        do_request data: { type: :custom_page, attributes: attrs }

        expect(status).to be(201)
        expect(response_body['data']).not_to be_nil
      end

      it 'creating sets location header', document: false do
        do_request data: { type: :custom_page, attributes: attrs }

        expect(response_headers['Location']).to match(%r{custom_pages\/\d+})
      end
    end

    it 'update a custom page' do
      do_request data: { type: :custom_page,
                         attributes: { translation_id: german_2, page_id: pages::Page13::ID, structure: structure } }

      expect(status).to be(200)
      expect(response_body['data']).not_to be_nil
    end
  end

  delete 'custom_pages/:id' do
    let(:id) { 1 }

    requires_authorization

    it 'delete a custom page' do
      do_request

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end

# frozen_string_literal: true

require 'acceptance_helper'

resource 'Pages' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.create!(access_code: AccessCode.find(1)).token }
  let(:test_structure) { '<?xml version="1.0" encoding="UTF-8" ?><page> new page </page>' }

  before do
    header 'Authorization', :authorization
  end

  post 'pages' do
    let(:attrs) { { filename: 'test.xml', structure: test_structure, resource_id: 2, position: 1 } }

    before do
      allow(Page).to(receive(:create!).with(ActionController::Parameters.new(attrs).permit!)
                         .and_return(Page.new(id: 12_345)))
    end

    requires_authorization

    before do
      allow(Page).to(receive(:create!).with(ActionController::Parameters.new(attrs).permit!)
                       .and_return(Page.new(id: 12_345)))
    end

    it 'create page' do
      do_request data: { type: :page, attributes: attrs }

      expect(status).to eq(201)
      expect(response_body['data']).not_to be_nil
    end

    it 'sets location header', document: false do
      do_request data: { type: :page, attributes: attrs }

      expect(response_headers['Location']).to eq('pages/12345')
    end
  end

  put 'pages/:id' do
    let(:id) { 1 }
    let(:attrs) { { structure: test_structure } }

    before do
      p = Page.find(1)
      allow(Page).to receive(:find).and_return(p)
      allow(p).to receive(:update!).with(ActionController::Parameters.new(attrs).permit!)
    end

    requires_authorization

    it 'edit page' do
      do_request data: { type: :page, attributes: attrs }

      expect(status).to eq(200)
      expect(response_body['data']).not_to be_nil
    end
  end
end

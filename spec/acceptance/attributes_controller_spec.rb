# frozen_string_literal: true

require 'acceptance_helper'

resource 'Attributes' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'
  let(:raw_post) { params.to_json }
  let(:godtools) { TestConstants::GodTools }
  let(:authorization) do
    AuthToken.create!(access_code: AccessCode.find(1)).token
  end

  post 'attributes/' do
    it 'does not allow unauthorized requests', document: false do
      header 'Authorization', nil

      do_request data: { type: :attribute, attributes: { key: 'foo', value: 'bar', resource_id: godtools::ID } }

      expect(status).to be(401)
    end

    it 'create an Attribute' do
      header 'Authorization', :authorization

      do_request data: { type: :attribute, attributes: { key: 'foo', value: 'bar', resource_id: godtools::ID } }

      expect(status).to be(204)
      expect(response_headers['Location']).to match(%r{attributes\/\d+})
      expect(response_body).to be_empty
    end
  end

  put 'attributes/:id' do
    header 'Authorization', :authorization
    let(:id) { godtools::Attributes::BannerImage::ID }

    it 'update an Attribute' do
      do_request data: { type: :attribute, attributes: { key: 'foo', value: 'new value', resource_id: godtools::ID } }

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end

  delete 'attributes/:id' do
    header 'Authorization', :authorization
    let(:id) { godtools::Attributes::BannerImage::ID }

    it 'delete an Attribute' do
      do_request

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec', 'support', 'mock_auth_helper.rb')

describe AttributesController do
  let(:godtools) { TestConstants::GodTools }

  it 'does not allow unauthorized POSTs' do
    post :create, params: { attribute: { key: 'foo', value: 'bar', resource_id: godtools::ID } }

    expect(response).to have_http_status(:unauthorized)
  end

  context 'authorized' do
    before(:each) do
      mock_auth
    end

    it 'creates an Attribute' do
      allow(Attribute).to receive(:create).and_return(Attribute.new(id: 100))

      post :create, params: { attribute: { key: 'foo', value: 'bar', resource_id: godtools::ID } }

      expect(response).to have_http_status(:created)
      expect(response.headers['Location']).to eq('attributes/100')
    end

    it 'updates an Attribute' do
      attribute = double
      allow(Attribute).to receive(:find).and_return(attribute)
      allow(attribute).to receive(:update)

      put :update, params: { id: godtools::Attributes::BannerImage::ID,
                             attribute: { key: 'foo', value: 'new value', resource_id: godtools::ID } }

      expect(response).to have_http_status(:no_content)
    end

    it 'deletes an Attribute' do
      attribute = double
      allow(Attribute).to receive(:find).and_return(attribute)
      allow(attribute).to receive(:destroy)

      delete :destroy, params: { id: godtools::Attributes::BannerImage::ID }

      expect(response).to have_http_status(:no_content)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec', 'support', 'mock_auth_helper.rb')

describe AttributesController do
  it 'does not allow unauthorized POSTs' do
    post :create, params: { attribute: { key: 'foo', value: 'bar', resource_id: 1 } }

    expect(response).to have_http_status(:unauthorized)
  end

  context 'authorized' do
    before(:each) do
      mock_auth
    end

    it 'creates an Attribute' do
      post :create, params: { attribute: { key: 'foo', value: 'bar', resource_id: 1 } }

      attribute = Attribute.order('id desc').first
      expect(attribute.key).to eq('foo')
      expect(attribute.value).to eq('bar')
      expect(attribute.resource_id).to eq(1)
    end

    it 'updates an Attribute' do
      put :update, params: { id: 1, attribute: { key: 'foo', value: 'new value', resource_id: 1 } }

      attribute = Attribute.find(1)
      expect(attribute.key).to eq('foo')
      expect(attribute.value).to eq('new value')
      expect(attribute.resource_id).to eq(1)
    end

    it 'deletes an Attribute' do
      delete :destroy, params: { id: 1 }

      expect { Attribute.find(1) }.to raise_error('Couldn\'t find Attribute with \'id\'=1')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec', 'support', 'mock_auth_helper.rb')

describe TranslatedAttributesController do
  it 'does not allow unauthorized POSTs' do
    post :create, params: { translated_attribute: { attribute_id: 'foo', translation_id: 1, value: 'translated attr' } }

    expect(response).to have_http_status(:unauthorized)
  end

  context 'authorized' do
    before(:each) do
      mock_auth
    end

    it 'creates a Translated Attribute' do
      allow(TranslatedAttribute).to receive(:create).and_return(TranslatedAttribute.new(id: 100))

      post :create, params: { translated_attribute: { attribute_id: 2, translation_id: 2, value: 'translated attr' } }

      expect(response).to have_http_status(:created)
      expect(response.headers['Location']).to eq('translated_attributes/100')
    end

    it 'updates a Translated Attribute' do
      attribute = double
      allow(TranslatedAttribute).to receive(:find).and_return(attribute)
      allow(attribute).to receive(:update)

      put :update,
          params: { id: 1, translated_attribute: { attribute_id: 2, translation_id: 3, value: 'updated translation' } }

      expect(response).to have_http_status(:no_content)
    end

    it 'deletes a Translated Attribute' do
      attribute = double
      allow(TranslatedAttribute).to receive(:find).and_return(attribute)
      allow(attribute).to receive(:destroy)

      delete :destroy, params: { id: 1 }

      expect(response).to have_http_status(:no_content)
    end
  end
end

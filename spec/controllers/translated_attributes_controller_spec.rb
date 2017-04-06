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
      post :create, params: { translated_attribute: { attribute_id: 2, translation_id: 2, value: 'translated attr' } }

      attribute = TranslatedAttribute.order('id desc').first
      expect(attribute.attribute_id).to eq(2)
      expect(attribute.translation_id).to eq(2)
      expect(attribute.value).to eq('translated attr')
    end

    it 'updates a Translated Attribute' do
      put :update,
          params: { id: 1, translated_attribute: { attribute_id: 2, translation_id: 3, value: 'updated translation' } }

      attribute = TranslatedAttribute.find(1)
      expect(attribute.attribute_id).to eq(2)
      expect(attribute.translation_id).to eq(3)
      expect(attribute.value).to eq('updated translation')
    end

    it 'deletes a Translated Attribute' do
      delete :destroy, params: { id: 1 }

      expect { TranslatedAttribute.find(1) }.to raise_error('Couldn\'t find TranslatedAttribute with \'id\'=1')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec', 'support', 'mock_auth_helper.rb')

describe CustomPagesController do
  let(:pages) { TestConstants::GodTools::Pages }
  let(:german_2) { TestConstants::GodTools::Translations::German2::ID }

  it 'does not allow unauthorized POSTs' do
    post :create, params: { translation_id: german_2, page_id: pages::Page4::ID, structure: '<custom>xml</custom>' }

    expect(response).to have_http_status(:unauthorized)
  end

  context 'authorized' do
    before(:each) do
      mock_auth
    end

    it 'creates the custom page if translation/page combination does not exist' do
      expect(CustomPage).to receive(:create!)

      post :create,
           params: { translation_id: german_2,
                     page_id: pages::Page4::ID,
                     structure: '<custom>This is some custom xml for one translation</custom>' }

      expect(response).to have_http_status(:created)
    end

    it 'updates the custom page if translation/page combination does exist' do
      expect(CustomPage).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
      expect(CustomPage).to receive(:find_by).and_return(double(update: true))

      post :create,
           params: { translation_id: german_2,
                     page_id: pages::Page4::ID,
                     structure: '<custom>This is some custom xml for one translation</custom>' }

      expect(response).to have_http_status(:no_content)
    end

    it 'destroys a custom page' do
      custom_page = double
      allow(CustomPage).to receive(:find).with('1').and_return(custom_page)
      allow(custom_page).to receive(:destroy)

      delete :destroy, params: { id: 1 }

      expect(response).to have_http_status(:no_content)
    end
  end
end

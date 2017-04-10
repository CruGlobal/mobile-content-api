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

    it 'adds new translation page if translation id/page id combo does not exist' do
      post :create,
           params: { translation_id: german_2,
                     page_id: pages::Page4::ID,
                     structure: '<custom>This is some custom xml for one translation</custom>' }

      expect(response).to have_http_status(:created)
      new_page = CustomPage.find_by(translation_id: german_2, page_id: pages::Page4::ID)
      expect(new_page).to_not be_nil
    end

    it 'updates structure of translation page if translation id/page id combo exists' do
      updated_structure = '<custom>This is some updated xml for one translation</custom>'
      post :create, params: { translation_id: german_2, page_id: pages::Page13::ID, structure: updated_structure }

      expect(response).to have_http_status(:no_content)
      page = CustomPage.find_by(translation_id: german_2, page_id: pages::Page13::ID)
      expect(page.structure).to eq(updated_structure)
    end
  end
end

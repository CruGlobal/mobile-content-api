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
    it 'upserts the custom page' do
      mock_auth
      allow(CustomPage).to receive(:upsert).and_return(:created)

      post :create,
           params: { translation_id: german_2,
                     page_id: pages::Page4::ID,
                     structure: '<custom>This is some custom xml for one translation</custom>' }

      expect(response).to have_http_status(:created)
    end
  end
end

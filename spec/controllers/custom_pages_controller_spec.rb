# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec', 'support', 'mock_auth_helper.rb')

describe CustomPagesController do
  it 'does not allow unauthorized POSTs' do
    post :create, params: { translation_id: 3, page_id: 2, structure: '<custom>xml</custom>' }

    expect(response.status).to be(401)
  end

  context 'authorized' do
    before(:each) do
      mock_auth
    end

    it 'adds new translation page if translation id/page id combo does not exist' do
      post :create,
           params: { translation_id: 3,
                     page_id: 2,
                     structure: '<custom>This is some custom xml for one translation</custom>' }

      expect(response.status).to be(201)
      new_page = CustomPage.find_by(translation_id: 3, page_id: 2)
      expect(new_page).to_not be_nil
    end

    it 'updates structure of translation page if translation id/page id combo exists' do
      updated_structure = '<custom>This is some updated xml for one translation</custom>'
      post :create, params: { translation_id: 3, page_id: 1, structure: updated_structure }

      expect(response.status).to be(204)
      page = CustomPage.find_by(translation_id: 3, page_id: 1)
      expect(page.structure).to eq(updated_structure)
    end
  end
end

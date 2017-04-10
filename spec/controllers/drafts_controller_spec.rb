# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec', 'support', 'mock_auth_helper.rb')

describe DraftsController do
  let(:languages) { TestConstants::Languages }
  let(:godtools) { TestConstants::GodTools }

  it 'does not allow unauthorized POSTs' do
    post :create, params: { resource_id: godtools::ID, language_id: languages::Slovak::ID }

    expect(response).to have_http_status(:unauthorized)
  end

  context 'authorized' do
    before(:each) do
      mock_auth
    end

    it 'downloads translated page with correct filename' do
      result = '{ \"1\": \"phrase\" }'

      translation = double
      allow(Translation).to receive(:find).and_return(translation)
      allow(translation).to receive(:download_translated_page).with('13_FinalPage.xml').and_return(result)

      get :show, params: { id: 2, page_id: godtools::Pages::Page13::ID }
      expect(response.body).to eq(result)
    end

    it 'creates new draft if resource/language combo does not exist' do
      allow(RestClient).to receive(:post)
      post :create, params: { resource_id: godtools::ID, language_id: languages::Slovak::ID }

      translation = Translation.where(resource_id: godtools::ID, language_id: languages::Slovak::ID, version: 1).first
      expect(translation).to_not be_nil
    end

    it 'increments version and creates new draft if resource/language translation exists' do
      post :create, params: { resource_id: godtools::ID, language_id: languages::English::ID }

      translation = Translation.where(resource_id: godtools::ID, language_id: languages::English::ID, version: 2).first
      expect(translation).to_not be_nil
    end

    it 'bad request returned if resource/language draft exists' do
      post :create, params: { resource_id: godtools::ID, language_id: languages::German::ID }

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to eq('Draft already exists for this resource and language.')
    end

    it 'edits a draft' do
      translation = double
      allow(Translation).to receive(:find).and_return(translation)
      allow(translation).to receive(:update_draft)

      put :update, params: { id: godtools::Translations::German2::ID, is_published: true }

      expect(response).to have_http_status(:no_content)
    end

    it 'delete draft' do
      delete :destroy, params: { id: godtools::Translations::German2::ID }

      expect(response).to have_http_status(:no_content)
    end
  end
end

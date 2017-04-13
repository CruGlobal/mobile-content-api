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
      allow(Translation).to receive(:find).with(godtools::Translations::German2::ID.to_s).and_return(translation)
      allow(translation).to receive(:download_translated_page).with('13_FinalPage.xml').and_return(result)

      get :show, params: { id: godtools::Translations::German2::ID, page_id: godtools::Pages::Page13::ID }
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(result)
    end

    context 'POST' do
      let(:resource) { double }

      before(:each) do
        allow(Resource).to receive(:find).and_return(resource)
        allow(resource).to receive(:id)
      end

      it 'creates new draft if resource/language combo does not exist' do
        allow(resource).to receive(:create_new_draft)
        allow(Translation).to receive(:latest_translation).and_return(nil)

        post :create, params: { resource_id: godtools::ID, language_id: languages::Slovak::ID }

        expect(response).to have_http_status(:no_content)
      end

      it 'increments version and creates new draft if resource/language translation exists' do
        existing_translation = double(is_published: true)
        allow(Translation).to receive(:latest_translation).and_return(existing_translation)
        allow(existing_translation).to receive(:create_new_version)

        post :create, params: { resource_id: godtools::ID, language_id: languages::English::ID }

        expect(response).to have_http_status(:no_content)
      end

      it 'bad request returned if resource/language draft exists' do
        existing_translation = double(is_published: false)
        allow(Translation).to receive(:latest_translation).and_return(existing_translation)

        post :create, params: { resource_id: godtools::ID, language_id: languages::German::ID }

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq('Draft already exists for this resource and language.')
      end
    end

    it 'edits a draft' do
      translation = double(update_draft: true)
      allow(Translation).to receive(:find).with(godtools::Translations::German2::ID.to_s).and_return(translation)

      put :update, params: { id: godtools::Translations::German2::ID, is_published: true }

      expect(response).to have_http_status(:no_content)
    end

    it 'delete draft' do
      translation = double(delete_draft!: :no_content)
      allow(Translation).to receive(:find).with(godtools::Translations::German2::ID.to_s).and_return(translation)

      delete :destroy, params: { id: godtools::Translations::German2::ID }

      expect(response).to have_http_status(:no_content)
    end
  end
end

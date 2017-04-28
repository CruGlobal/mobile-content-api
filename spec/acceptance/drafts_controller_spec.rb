# frozen_string_literal: true

require 'acceptance_helper'

resource 'Drafts' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }
  let(:languages) { TestConstants::Languages }
  let(:godtools) { TestConstants::GodTools }
  let(:authorization) do
    AuthToken.create(access_code: AccessCode.find(1)).token
  end

  get 'drafts/:id' do
    let(:id) { godtools::Translations::German2::ID }

    it 'get translated page' do
      header 'Authorization', :authorization
      result = '{ \"1\": \"phrase\" }'
      translation = double
      allow(Translation).to receive(:find).with(godtools::Translations::German2::ID.to_s).and_return(translation)
      allow(translation).to(
        receive(:build_translated_page).with(godtools::Pages::Page13::ID.to_s, false).and_return(result)
      )

      do_request page_id: godtools::Pages::Page13::ID

      expect(status).to be(200)
      expect(response_body).to eq(result)
    end

    it 'get translation page without authorization', document: false do
      header 'Authorization', nil

      do_request page_id: godtools::Pages::Page13::ID

      expect(status).to be(401)
    end
  end

  post 'drafts' do
    header 'Authorization', :authorization
    let(:resource) { double }
    let(:resource_id) { godtools::ID }

    before(:each) do
      allow(Resource).to receive(:find).with(resource_id).and_return(resource)
      allow(resource).to receive(:id).and_return(resource_id)
    end

    it 'create draft with new resource/language combination' do
      language_id = languages::Slovak::ID
      allow(Translation).to receive(:latest_translation).with(resource_id, language_id).and_return(nil)
      allow(resource).to receive(:create_new_draft).with(language_id)

      do_request data: { type: :translation, attributes: { resource_id: resource_id, language_id: language_id } }

      expect(status).to be(204)
    end

    it 'create draft with existing resource/language combination' do
      existing_translation = double(is_published: true)
      language_id = languages::Slovak::ID
      allow(Translation).to receive(:latest_translation).with(resource_id, language_id).and_return(existing_translation)
      allow(existing_translation).to receive(:create_new_version)

      do_request data: { type: :translation, attributes: { resource_id: resource_id, language_id: language_id } }

      expect(status).to be(204)
    end

    it 'create draft with resource/language combination for an existing draft' do
      language_id = languages::German::ID
      allow(Translation).to receive(:latest_translation).with(resource_id, language_id).and_return(Translation.find(3))

      do_request data: { type: :translation, attributes: { resource_id: resource_id, language_id: language_id } }

      expect(status).to be(400)
      expect(JSON.parse(response_body)['errors'][0]['detail']).to(
        eq('Draft already exists for this resource and language.')
      )
    end
  end

  put 'drafts/:id' do
    let(:id) { godtools::Translations::German2::ID }
    header 'Authorization', :authorization

    it 'update draft' do
      translation = double(update_draft: true)
      allow(Translation).to receive(:find).with(godtools::Translations::German2::ID.to_s).and_return(translation)

      do_request data: { type: :translation, attributes: { is_published: true } }

      expect(status).to be(204)
    end
  end

  delete 'drafts/:id' do
    header 'Authorization', :authorization
    let(:id) { 1 }
    let(:translation) { double }

    before(:each) do
      allow(Translation).to receive(:find).with(id.to_s).and_return(translation)
    end

    it 'delete draft' do
      allow(translation).to receive(:destroy!)

      do_request

      expect(status).to be(204)
    end

    it 'delete translation' do
      allow(translation).to receive(:destroy!).and_raise(Error::TranslationError, 'Cannot delete published drafts.')

      do_request

      expect(status).to be(400)
    end
  end
end

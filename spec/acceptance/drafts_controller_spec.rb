# frozen_string_literal: true

require 'acceptance_helper'

resource 'Drafts' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }
  let(:languages) { TestConstants::Languages }
  let(:godtools) { TestConstants::GodTools }
  let(:authorization) do
    AuthToken.create!(access_code: AccessCode.find(1)).token
  end

  before do
    header 'Authorization', :authorization
  end

  get 'drafts/' do
    requires_authorization

    it 'get all drafts ' do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)['data'].size).to be(2)
    end
  end

  get 'drafts/:id' do
    let(:id) { godtools::Translations::German2::ID }

    requires_authorization

    it 'get translated page' do
      result = '{ \"1\": \"phrase\" }'
      translation = double
      allow(Translation).to receive(:find).with(godtools::Translations::German2::ID.to_s).and_return(translation)
      allow(translation).to(
        receive(:translated_page).with(godtools::Pages::Page13::ID.to_s, false).and_return(result)
      )

      do_request page_id: godtools::Pages::Page13::ID

      expect(status).to be(200)
      expect(response_body).to eq(result)
    end
  end

  post 'drafts' do
    let(:resource) { double }
    let(:resource_id) { godtools::ID }

    before do
      allow(Resource).to receive(:find).with(resource_id).and_return(resource)
      allow(resource).to receive(:id).and_return(resource_id)
    end

    requires_authorization

    context 'new resource/language combination' do
      let(:id) { 100 }

      before do
        language_id = languages::Slovak::ID
        allow(Translation).to receive(:latest_translation).with(resource_id, language_id).and_return(nil)
        allow(resource).to receive(:create_new_draft).with(language_id).and_return(Translation.new(id: id))

        do_request data: { type: :translation, attributes: { resource_id: resource_id, language_id: language_id } }
      end

      it 'create draft with new resource/language combination' do
        expect(status).to be(201)
        expect(response_body['data']).not_to be_nil
      end

      it 'returns location header', document: false do
        expect(response_headers['Location']).to eq("drafts/#{id}")
      end
    end

    context 'existing resource/language combination' do
      let(:id) { 101 }

      before do
        existing = instance_double(Translation, is_published: true)
        language_id = languages::Slovak::ID
        allow(Translation).to receive(:latest_translation).with(resource_id, language_id).and_return(existing)
        allow(existing).to receive(:create_new_version).and_return(Translation.new(id: id))

        do_request data: { type: :translation, attributes: { resource_id: resource_id, language_id: language_id } }
      end

      it 'create draft with existing resource/language combination' do
        expect(status).to be(201)
        expect(response_body['data']).not_to be_nil
      end

      it 'returns location header', document: false do
        expect(response_headers['Location']).to eq("drafts/#{id}")
      end
    end
  end

  put 'drafts/:id' do
    let(:id) { godtools::Translations::German2::ID }

    requires_authorization

    it 'update draft' do
      translation = Translation.find(3)
      allow(Translation).to receive(:find).with(godtools::Translations::German2::ID.to_s).and_return(translation)
      params = { is_published: true }
      allow(translation).to receive(:update_draft).with(ActionController::Parameters.new(params))

      do_request data: { type: :translation, attributes: params }

      expect(status).to be(200)
      expect(response_body['data']).not_to be_nil
    end

    it 'update draft without translating all phrases' do
      translation = Translation.find(1)
      allow(translation).to receive(:update_draft).and_raise(Error::TextNotFoundError, 'Translated phrase not found.')
      allow(Translation).to receive(:find).with(godtools::Translations::German2::ID.to_s).and_return(translation)

      do_request data: { type: :translation, attributes: { is_published: true } }

      expect(status).to be(409)
    end
  end

  delete 'drafts/:id' do
    let(:id) { 1 }
    let(:translation) { double }

    before do
      allow(Translation).to receive(:find).with(id.to_s).and_return(translation)
    end

    requires_authorization

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

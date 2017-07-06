# frozen_string_literal: true

require 'acceptance_helper'
require 'page_util'

resource 'Resources' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'
  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.create!(access_code: AccessCode.find(1)).token }

  get 'resources/' do
    it 'get all resources' do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)['data'].count).to be(3)
    end

    it 'includes no objects by default', document: false do
      do_request

      expect(JSON.parse(response_body)['included']).to be_nil
    end

    it 'get all resources with system name' do
      do_request 'filter[system]': 'GodTools'

      expect(status).to be(200)
      expect(JSON.parse(response_body)['data'].count).to be(2)
    end

    it 'get all resources, include translations' do
      do_request 'filter[system]': 'GodTools', include: :translations

      expect(status).to be(200)
      expect(JSON.parse(response_body)['included'].count).to be(8)
    end
  end

  get 'resources/:id' do
    let(:id) { 1 }

    it 'get resource' do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)['data']['attributes'].size).to be(8)
    end

    it 'includes no objects by default', document: false do
      do_request

      expect(JSON.parse(response_body)['included']).to be_nil
    end

    it 'get resource, include translations' do
      do_request include: :translations

      expect(status).to be(200)
      expect(JSON.parse(response_body)['included'].count).to be(3)
    end

    it 'has custom attributes', document: false do
      do_request

      attrs = JSON.parse(response_body)['data']['attributes']
      expect(attrs['attr-banner-image']).to eq('this is a location')
      expect(attrs['attr-translate-me']).to eq('base language')
    end

    it 'has total shares', document: false do
      do_request

      attrs = JSON.parse(response_body)['data']['attributes']
      expect(attrs['total-views']).to be(1268)
    end
  end

  context 'PUT do' do
    let(:id) { 1 }
    let(:manifest) do
      '<manifest xmlns="https://mobile-content-api.cru.org/xmlns/manifest"
                        xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
       </manifest>'
    end
    let(:page_util) do
      page_util = instance_double(PageUtil, push_new_onesky_translation: nil)
      page_util
    end

    before do
      header 'Authorization', :authorization
      allow(PageUtil).to receive(:new).with(resource_id(id), 'en').and_return(page_util)
    end

    put 'resources/:id' do
      parameter :name, 'Resource name'
      parameter :abbreviation, 'Abbreviation'
      parameter :manifest, 'Base manifest XML'
      parameter :onesky_project_id, 'Setting this will cause this resource to use OneSky'
      parameter :system_id, 'Parent system'
      parameter :description, 'Description'

      requires_authorization

      it 'update resource' do
        do_request data: { type: :resource, attributes: { description: 'hello, world', manifest: manifest } }

        expect(status).to be(200)
        expect(response_body).not_to be_nil
      end
    end

    put 'resources/:id/onesky?keep-existing-phrases=:is_keeping' do
      parameter 'keep-existing-phrases',
                'Query string parameter.  If false, deprecate phrases not pushed to OneSky in this update.'

      let(:is_keeping) { false }

      requires_authorization

      it 'update resource in OneSky' do
        do_request

        expect(page_util).to have_received(:push_new_onesky_translation).with(is_keeping.to_s)
      end

      it 'returns 204 with empty body', document: false do
        do_request

        expect(status).to be(204)
        expect(response_body).to be_empty
      end
    end
  end

  private

  RSpec::Matchers.define :resource_id do |id|
    match { |actual| (actual.id == id) }
  end
end

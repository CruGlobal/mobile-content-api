# frozen_string_literal: true

require 'acceptance_helper'
require 'page_util'

resource 'Resources' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'
  let(:raw_post) { params.to_json }

  get 'resources/' do
    it 'get all resources' do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)['data'].count).to be(3)
      expect(JSON.parse(response_body)['included']).to be(nil)
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
      expect(JSON.parse(response_body)['included']).to be(nil)
    end

    it 'get resource, include translations' do
      do_request include: :translations

      expect(status).to be(200)
      expect(JSON.parse(response_body)['included'].count).to be(3)
    end

    it 'has custom attributes', document: false do
      do_request

      expect(status).to be(200)
      attrs = JSON.parse(response_body)['data']['attributes']
      expect(attrs['attr-banner-image']).to eq('this is a location')
      expect(attrs['attr-translate-me']).to eq('base language')
    end

    it 'has custom attachments', document: false do
      do_request

      expect(status).to be(200)
      attrs = JSON.parse(response_body)['data']['attributes']
      expect(attrs['attr-kgp-logo']).to(
        match(%r{\A\/system\/attachments\/files\/000\/000\/002\/original\/wall.jpg\?\d+\z})
      )
    end

    it 'has total shares', document: false do
      do_request

      expect(status).to be(200)
      attrs = JSON.parse(response_body)['data']['attributes']
      expect(attrs['total-views']).to be(1268)
    end
  end

  put 'resources/:id' do
    let(:id) { 1 }

    parameter 'keep-existing-phrases',
              'Query string parameter.  If false, deprecate phrases not pushed to OneSky in this update.'

    it 'requires authorization', document: false do
      header 'Authorization', nil
      allow(PageUtil).to receive(:new).with(resource_id(1), 'en').and_return(double(push_new_onesky_translation: nil))

      do_request

      expect(status).to be(401)
    end

    it 'update resource in OneSky' do
      header 'Authorization', AuthToken.create(access_code: AccessCode.find(1)).token
      page_util = double
      allow(page_util).to receive(:push_new_onesky_translation).with(false)
      allow(PageUtil).to receive(:new).with(resource_id(1), 'en').and_return(page_util)

      do_request 'keep-existing-phrases': false

      expect(status).to be(204)
    end
  end

  private

  RSpec::Matchers.define :resource_id do |id|
    match { |actual| (actual.id == id) }
  end
end

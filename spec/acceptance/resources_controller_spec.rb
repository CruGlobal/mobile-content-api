# frozen_string_literal: true

require 'acceptance_helper'

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
      expect(attrs.size).to be(6)
      expect(attrs['attr-banner image']).to eq('this is a location')
      expect(attrs['attr-translate me']).to eq('base language')
    end
  end
end

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
      expect(JSON.parse(response_body)['data']['attributes'].size).to be(7)
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

  put 'resources/:id' do
    let(:id) { 1 }

    before do
      header 'Authorization', :authorization
    end

    parameter 'keep-existing-phrases',
              'Query string parameter.  If false, deprecate phrases not pushed to OneSky in this update.'

    requires_authorization

    it 'update resource in OneSky' do
      mock_page_util(id)

      do_request 'keep-existing-phrases': false

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end

  private

  def mock_page_util(resource_id)
    page_util = double
    allow(page_util).to receive(:push_new_onesky_translation).with(false)
    allow(PageUtil).to receive(:new).with(resource_id(resource_id), 'en').and_return(page_util)
  end

  RSpec::Matchers.define :resource_id do |id|
    match { |actual| (actual.id == id) }
  end
end

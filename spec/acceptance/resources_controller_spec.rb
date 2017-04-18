# frozen_string_literal: true

require 'rails_helper'
require 'page_util'
require 'rspec_api_documentation'
require 'rspec_api_documentation/dsl'

resource 'Resources' do
  get 'resources/' do
    it 'returns all Resources by default' do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)['data'].count).to be(3)
    end

    it 'can filter by resource name' do
      do_request 'filter[system]': 'GodTools'

      expect(status).to be(200)
      expect(JSON.parse(response_body)['data'].count).to be(2)
    end
  end

  get 'resources/:id' do
    let(:id) { 1 }

    it 'includes latest translations by default' do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)['included'].count).to be(2)
    end

    it 'includes all when specified' do
      do_request include: :translations

      expect(status).to be(200)
      expect(JSON.parse(response_body)['included'].count).to be(3)
    end
  end
end

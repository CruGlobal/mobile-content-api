# frozen_string_literal: true

require 'acceptance_helper'

resource 'Resources' do
  get 'resources/' do
    it 'get all resources' do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)['data'].count).to be(3)
    end

    it 'get all resources with specific system name' do
      do_request 'filter[system]': 'GodTools'

      expect(status).to be(200)
      expect(JSON.parse(response_body)['data'].count).to be(2)
    end
  end

  get 'resources/:id' do
    let(:id) { 1 }

    it 'get resource' do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)['included'].count).to be(2)
    end

    it 'get resource, include translations' do
      do_request include: :translations

      expect(status).to be(200)
      expect(JSON.parse(response_body)['included'].count).to be(3)
    end
  end
end

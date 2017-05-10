# frozen_string_literal: true

require 'acceptance_helper'

resource 'Languages' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.create(access_code: AccessCode.find(1)).token }

  get 'languages' do
    it 'get all languages' do
      do_request

      expect(status).to be(200)
    end
  end

  get 'languages/:id' do
    let(:id) { 2 }

    it 'get language' do
      do_request

      expect(status).to be(200)
    end
  end

  post 'languages' do
    it 'requires authorization', document: false do
      header 'Authorization', nil

      do_request data: { type: :language, attributes: { name: 'Elvish', code: 'ev' } }

      expect(status).to be(401)
    end

    it 'create a language' do
      header 'Authorization', authorization

      do_request data: { type: :language, attributes: { name: 'Elvish', code: 'ev' } }

      expect(status).to be(201)
      expect(response_headers['Location']).to match(%r{languages\/\d+})
    end
  end

  delete 'languages/:id' do
    let(:id) { 1 }

    it 'requires authorization', document: false do
      header 'Authorization', nil

      do_request

      expect(status).to be(401)
    end

    it 'delete a language' do
      header 'Authorization', authorization

      do_request

      expect(status).to be(204)
    end
  end
end

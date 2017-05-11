# frozen_string_literal: true

require 'acceptance_helper'

resource 'Translations' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  get 'translations' do
    it 'get all translations ' do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)['data'].size).to be(7)
    end
  end

  get 'translations/:id' do
    it 'get a translation' do
      id = 1
      translation = Translation.find(id)
      allow(Translation).to receive(:find).with(id.to_s).and_return(translation)
      expect(translation).to receive(:s3_uri).and_return('google.com')

      do_request id: id

      expect(status).to be(302)
    end

    it 'get a draft' do
      do_request id: 3

      expect(status).to be(404)
      expect(JSON.parse(response_body)['data']).to be_nil
    end
  end
end

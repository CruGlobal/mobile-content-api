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
      # rubocop:disable AnyInstance
      allow_any_instance_of(Translation).to receive(:s3_url).and_return('www.google.com')
      id = 1

      do_request id: id

      expect(status).to be(302)
    end

    context 'get a draft' do
      let(:id) { 3 }

      it 'get a draft' do
        do_request id: id

        expect(status).to be(404)
        expect(JSON.parse(response_body)['data']).to be_nil
      end

      it 'ID is returned in error message' do
        do_request id: id

        expect(JSON.parse(response_body)['errors'][0]['detail']).to include("Translation with ID: #{id} not found")
      end
    end
  end
end

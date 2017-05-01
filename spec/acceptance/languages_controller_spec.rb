# frozen_string_literal: true

require 'acceptance_helper'

resource 'Languages' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }

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
end

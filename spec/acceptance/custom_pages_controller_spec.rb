# frozen_string_literal: true

require 'acceptance_helper'

resource 'CustomPages' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }
  let(:pages) { TestConstants::GodTools::Pages }
  let(:german_2) { TestConstants::GodTools::Translations::German2::ID }
  let(:authorization) do
    AuthToken.create(access_code: AccessCode.find(1)).token
  end

  post 'custom_pages/' do
    it 'does not allow unauthorized requests', document: false do
      header 'Authorization', nil

      do_request translation_id: german_2, page_id: pages::Page4::ID, structure: '<custom>xml</custom>'

      expect(status).to be(401)
    end

    it 'create a custom page' do
      header 'Authorization', :authorization
      expect(CustomPage).to receive(:create!)

      do_request translation_id: german_2,
                 page_id: pages::Page4::ID,
                 structure: '<custom>This is some custom xml for one translation</custom>'

      expect(status).to be(201)
    end

    it 'update a custom page' do
      header 'Authorization', :authorization
      expect(CustomPage).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
      expect(CustomPage).to receive(:find_by).and_return(double(update: true))

      do_request translation_id: german_2,
                 page_id: pages::Page4::ID,
                 structure: '<custom>This is some custom xml for one translation</custom>'

      expect(status).to be(204)
    end
  end

  delete 'custom_pages/:id' do
    header 'Authorization', :authorization

    let(:id) { 1 }

    it 'delete a custom page' do
      custom_page = double
      allow(CustomPage).to receive(:find).with('1').and_return(custom_page)
      allow(custom_page).to receive(:destroy)

      do_request

      expect(status).to be(204)
    end
  end
end

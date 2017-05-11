# frozen_string_literal: true

require 'acceptance_helper'

resource 'TranslatedAttributes' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'

  let(:raw_post) { params.to_json }
  let(:godtools) { TestConstants::GodTools }
  let(:authorization) do
    AuthToken.create(access_code: AccessCode.find(1)).token
  end

  post 'translated_attributes' do
    it 'does not allow unauthorized requests', document: false do
      header 'Authorization', nil

      do_request data: { type: :translated_attribute,
                         attributes: { attribute_id: 'foo',
                                       translation_id: godtools::Translations::English::ID,
                                       value: 'translated attr' } }

      expect(status).to be(401)
    end

    it 'create a Translated Attribute' do
      header 'Authorization', :authorization
      allow(TranslatedAttribute).to receive(:create).and_return(TranslatedAttribute.new(id: 100))

      do_request data: { type: :translated_attribute,
                         attributes: { attribute_id: godtools::Attributes::TranslatableAttr::ID,
                                       translation_id: godtools::Translations::German1::ID,
                                       value: 'translated attr' } }

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end

  put 'translated_attributes/:id' do
    header 'Authorization', :authorization

    let(:id) { 1 }

    it 'update a Translated Attribute' do
      attribute = double
      allow(TranslatedAttribute).to receive(:find).and_return(attribute)
      allow(attribute).to receive(:update)

      do_request data: { type: :translated_attribute,
                         attributes: { attribute_id: godtools::Attributes::TranslatableAttr::ID,
                                       translation_id: godtools::Translations::German2::ID,
                                       value: 'updated translation' } }

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end

  delete 'translated_attributes/:id' do
    header 'Authorization', :authorization

    let(:id) { 1 }

    it 'delete a Translated Attribute' do
      attribute = double
      allow(TranslatedAttribute).to receive(:find).and_return(attribute)
      allow(attribute).to receive(:destroy)

      do_request

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end

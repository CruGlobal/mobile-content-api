# frozen_string_literal: true

require 'rails_helper'
require 'page_client'

describe Resource do
  let(:resource) { described_class.find(2) }

  context 'creating a new draft' do
    let(:language) { Language.find(3) }

    it 'pushes to OneSky' do
      allow(PageClient).to(receive(:new).with(resource, language.code)
                           .and_return(instance_double(PageClient, push_new_onesky_translation: :created)))

      resource.create_new_draft(language.id)
    end

    it 'adds a new record to the database' do
      allow(PageClient).to receive(:new).with(resource, language.code).and_return(double.as_null_object)

      result = resource.create_new_draft(language.id)

      expect(result).not_to be_nil
    end
  end

  context 'returns latest published translation for each language' do
    let(:latest_translations) { resource.latest_translations }

    it 'resource has 2 translations' do
      expect(latest_translations.count).to be(2)
    end

    it 'returns highest version for each language' do
      expect(latest_translations[0][:id]).to eq(5)
      expect(latest_translations[1][:id]).to eq(8)
    end
  end

  context 'returns latest translation (published or not) for each language' do
    let(:latest_drafts_translations) { resource.latest_drafts_translations }

    it 'resource has 2 translations' do
      expect(latest_drafts_translations.count).to be(2)
    end

    it 'returns highest version for each language' do
      expect(latest_drafts_translations[0][:id]).to eq(6)
      expect(latest_drafts_translations[1][:id]).to eq(8)
    end

    it 'is ordered by language' do
      r = described_class.find(1)

      r.create_new_draft(1)

      expect(r.latest_drafts_translations[0][:id]).to eq(9)
      expect(r.latest_drafts_translations[1][:id]).to eq(3)
    end
  end

  it 'validates manifest if present' do
    attributes = { name: 'test', abbreviation: 't', system_id: 1, resource_type_id: 1, manifest: '<xml>bad xml</xml>' }

    result = described_class.create(attributes)

    expect(result).not_to be_valid
    expect(result.errors['manifest'])
      .to include("1:0: ERROR: Element 'xml': No matching global declaration available for the validation root.")
  end
end

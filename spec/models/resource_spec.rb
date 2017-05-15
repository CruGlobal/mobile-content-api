# frozen_string_literal: true

require 'rails_helper'
require 'page_util'

describe Resource do
  let(:resource) { described_class.find(TestConstants::Satisfied::ID) }

  context 'creating a new draft' do
    let(:language) { Language.find(1) }

    it 'pushes to OneSky' do
      allow(PageUtil).to(receive(:new).with(resource, language.code)
                           .and_return(instance_double(PageUtil, push_new_onesky_translation: :created)))

      resource.create_new_draft(language.id)
    end

    it 'adds a new record to the database' do
      allow(PageUtil).to receive(:new).with(resource, language.code).and_return(double.as_null_object)

      result = resource.create_new_draft(language.id)

      expect(result).not_to be_nil
    end
  end

  it 'returns latest published translation for each language' do
    latest_translations = resource.latest_translations

    expect(latest_translations.count).to be(2)
    expect(latest_translations[0][:id]).to eq(5)
    expect(latest_translations[1][:id]).to eq(8)
  end
end

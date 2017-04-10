# frozen_string_literal: true

require 'rails_helper'

describe Resource do
  it 'returns latest published translation for each language' do
    resource = Resource.find(TestConstants::Satisfied::ID)

    latest_translations = resource.latest_translations

    expect(latest_translations.count).to be(2)
    expect(latest_translations[0][:id]).to eq(5)
    expect(latest_translations[1][:id]).to eq(8)
  end
end

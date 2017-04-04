# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('app', 'serializers', 'resource_serializer.rb')

describe ResourceSerializer do
  it 'returns latest published translation for each language' do
    resource = Resource.find(2)
    serializer = ResourceSerializer.new(resource)
    serialization = ActiveModelSerializers::Adapter.create(serializer)

    latest_translations = serialization.as_json[:data][:relationships][:'latest-translations'][:data]
    expect(latest_translations.count).to be(2)
    expect(latest_translations[0][:id]).to eq('5')
    expect(latest_translations[1][:id]).to eq('8')
  end
end

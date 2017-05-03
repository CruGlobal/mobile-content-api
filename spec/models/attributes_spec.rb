# frozen_string_literal: true

require 'rails_helper'

describe Attribute do
  it 'resource/key combination must be unique and is not case sensitive' do
    attr = Attribute.create(resource_id: 1, key: 'baNNer_IMage', value: 'bar')

    expect(attr).to_not be_valid
    expect(attr.errors[:resource]).to include 'has already been taken'
  end

  it 'key cannot end in underscore' do
    attr = Attribute.create(resource_id: 1,
                            key: 'roger_',
                            value: 'test')

    expect(attr).to_not be_valid
    expect(attr.errors[:key]).to include 'is invalid'
  end

  it 'key cannot have spaces' do
    attr = Attribute.create(resource_id: 1,
                            key: 'roger the dog',
                            value: 'test')

    expect(attr).to_not be_valid
    expect(attr.errors[:key]).to include 'is invalid'
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe Attribute do
  it 'resource/key combination must be unique and is not case sensitive' do
    expect do
      Attribute.create!(resource_id: 1,
                        key: 'baNNer_IMage',
                        value: 'bar')
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'key cannot end in underscore' do
    expect do
      Attribute.create!(resource_id: 1,
                        key: 'roger_',
                        value: 'test')
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'key cannot have spaces' do
    expect do
      Attribute.create!(resource_id: 1,
                        key: 'roger the dog',
                        value: 'test')
    end.to raise_error(ActiveRecord::RecordInvalid)
  end
end

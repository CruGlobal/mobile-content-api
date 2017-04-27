# frozen_string_literal: true

require 'rails_helper'

describe Attribute do
  it 'resource/key combination must be unique' do
    expect do
      Attribute.create!(resource_id: 1,
                        key: 'Banner_Image',
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

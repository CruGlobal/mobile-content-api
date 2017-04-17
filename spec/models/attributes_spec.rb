# frozen_string_literal: true

require 'rails_helper'

describe Attribute do
  it 'resource/key combination must be unique' do
    expect do
      Attribute.create(resource_id: 1,
                       key: 'Banner Image',
                       value: 'bar')
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end
end

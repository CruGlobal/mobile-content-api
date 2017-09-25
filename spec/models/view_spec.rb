# frozen_string_literal: true

require 'rails_helper'

describe View do
  it 'must be greater than zero' do
    result = described_class.create(resource_id: 1, quantity: 0)

    expect(result.errors[:quantity]).to include('must be greater than 0')
  end
end

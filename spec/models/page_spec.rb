# frozen_string_literal: true

require 'rails_helper'

describe Page do
  it 'cannot duplicate Resource ID and Page position' do
    result = described_class.create(filename: 'blahblah.xml', resource_id: 1, structure: 'structure data', position: 1)

    expect(result).not_to be_valid
  end
end

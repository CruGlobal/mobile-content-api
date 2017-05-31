# frozen_string_literal: true

require 'rails_helper'

describe OneskyPhrase do
  it 'cannot be created for projects not using OneSky' do
    result = described_class.create(text: 'hooray', page_id: 3, onesky_id: 'f6d2ee81-f952-423f-8fd5-a2ecfc08cd79')

    expect(result).not_to be_valid
    expect(result.errors['page']).to include('Does not use OneSky.')
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe TranslatedPage do
  it 'cannot be created for projects not using OneSky' do
    result = described_class.create(value: 'what a beautiful day', page_id: 1, translation_id: 3)

    expect(result).not_to be_valid
    expect(result.errors['page']).to include('Uses OneSky.')
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe CustomPage do
  it 'cannot be replicated' do
    page = described_class.create(translation_id: 3, page_id: 1, structure: '{ <xml>updated structure</xml> }')

    expect(page).not_to be_valid
    expect(page.errors[:translation]).to include 'has already been taken'
  end
end

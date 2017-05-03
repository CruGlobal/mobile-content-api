# frozen_string_literal: true

require 'rails_helper'

describe CustomPage do
  it 'cannot be replicated' do
    page = CustomPage.create(translation_id: 3, page_id: 1, structure: '{ <xml>updated structure</xml> }')

    expect(page).to_not be_valid
    expect(page.errors[:translation]).to include 'has already been taken'
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe AbstractPage do
  it 'validates XML on create' do
    result = Page.create(filename: 'test.xml', resource_id: 1, structure: 'invalid XML', position: 1)

    expect(result).not_to be_valid
    expect(result.errors['structure']).to include('-1:0: ERROR: The document has no document element.')
  end

  it 'validates XML on update' do
    custom_page = CustomPage.find(1)

    custom_page.update(structure: 'invalid XML')

    expect(custom_page).not_to be_valid
    expect(custom_page.errors['structure']).to include('-1:0: ERROR: The document has no document element.')
  end
end

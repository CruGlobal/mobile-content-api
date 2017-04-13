# frozen_string_literal: true

require 'rails_helper'

describe CustomPage do
  let(:translation_id) { 3 }

  it 'adds a new custom page' do
    result = CustomPage.upsert(translation_id: translation_id, page_id: 2, structure: '{ <xml>structure</xml> }')

    expect(result).to be(:created)
  end

  it 'updates an existing custom page if the translation/page combination exists' do
    page_id = 1
    structure = '{ <xml>updated structure</xml> }'

    result = CustomPage.upsert(
      ActionController::Parameters.new(translation_id: translation_id, page_id: page_id, structure: structure)
    )

    expect(result).to be(:no_content)
    expect(CustomPage.find_by(translation_id: translation_id, page_id: page_id).structure).to eq(structure)
  end
end

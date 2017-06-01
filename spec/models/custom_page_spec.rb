# frozen_string_literal: true

require 'rails_helper'

describe CustomPage do
  let(:translation_id) { 3 }
  let(:page_id) { 1 }
  let(:valid_xml) do
    '<?xml version="1.0" encoding="UTF-8" ?>
<page xmlns="https://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
</page>'
  end

  it 'Translation/Page combination cannot be replicated' do
    result = described_class.create(translation_id: translation_id, page_id: page_id, structure: valid_xml)

    expect(result).not_to be_valid
    expect(result.errors[:translation]).to include 'has already been taken'
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe Page do
  let(:id_1) { '5dadce9b-b881-439e-86b6-a2faac5367fc' }
  let(:id_2) { 'df7795f5-d629-41f2-a94c-cacfc0b87125' }
  let(:id_3) { 'f9894df9-df1d-4831-9782-345028c6c9a2' }

  let(:p_1) { 'test phrase one' }
  let(:p_2) { 'test phrase two' }
  let(:p_3) { 'test phrase three' }

  let(:structure) do
    "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<page xmlns=\"https://mobile-content-api.cru.org/xmlns/tract\"
      xmlns:content=\"https://mobile-content-api.cru.org/xmlns/content\">
  <hero>
    <heading>
      <content:text i18n-id=\"#{id_1}\">#{p_1}</content:text>
    </heading>

    <paragraph>
      <content:text i18n-id=\"#{id_2}\">#{p_2}</content:text>
    </paragraph>

    <paragraph>
      <content:text i18n-id=\"#{id_3}\">#{p_3}</content:text>
    </paragraph>
  </hero>
</page>"
  end

  it 'cannot duplicate Resource ID and Page position' do
    result = described_class.create(filename: 'blahblah.xml',
                                    resource_id: 1,
                                    structure: structure,
                                    position: 1)

    expect(result).not_to be_valid
  end

  it 'parses OneSky phrases from page structure' do
    page = described_class.find(1)
    allow(page).to receive(:structure).and_return(structure)

    result = page.onesky_phrases

    expect(result).to eq(id_1 => p_1, id_2 => p_2, id_3 => p_3)
  end
end

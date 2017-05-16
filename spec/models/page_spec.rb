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
<!-- https://projects.invisionapp.com/d/main#/console/10765517/228342261/preview -->
<page xmlns=\"http://mobile-content-api.cru.org/xmlns/tract\"
      xmlns:content=\"https://mobile-content-api.cru.org/xmlns/content\">
  <header>
    <number>
      <content:text i18n-id=\"#{id_1}\">#{p_1}</content:text>
    </number>
  </header>
  <card>
    <label>
      <content:text i18n-id=\"#{id_2}\">#{p_2}</content:text>
    </label>
    <paragraph>
      <content:text i18n-id=\"#{id_3}\">#{p_3}</content:text>
    </paragraph>
  </card>
</page>"
  end

  context 'creating' do
    it 'creates a TranslationElement for each translatable XML element' do
      allow(TranslationElement).to receive(:create!).exactly(3).times

      p = described_class.create!(structure: structure, filename: 'testing.xml', resource_id: 1, position: 2)

      expect(TranslationElement).to(have_received(:create!).with(page: p, onesky_phrase_id: id_1, text: p_1)
                                      .with(page: p, onesky_phrase_id: id_2, text: p_2)
                                      .with(page: p, onesky_phrase_id: id_3, text: p_3))
    end

    it 'cannot duplicate Resource ID and Page position' do
      result = described_class.create(filename: 'blahblah.xml',
                                      resource_id: 1,
                                      structure: 'structure data',
                                      position: 1)

      expect(result).not_to be_valid
    end

    it 'does not create Pages for Resources not using OneSky' do
      allow(TranslationElement).to receive(:create!).exactly(0).times

      described_class.create!(structure: structure, filename: 'testing.xml', resource_id: 3, position: 3)
    end
  end

  context 'updating' do
    let(:p) { described_class.find(1) }

    it 'adds new translation elements' do
      allow(TranslationElement).to receive(:create!).exactly(2).times

      p.update!(structure: structure)

      expect(TranslationElement).to(have_received(:create!).with(page: p, onesky_phrase_id: id_1, text: p_1)
                                      .with(page: p, onesky_phrase_id: id_2, text: p_2))
    end

    it 'updates text for existing translation elements' do
      p.update!(structure: structure)

      element = TranslationElement.find_by!(page: p, onesky_phrase_id: id_3)
      expect(element.text).to eq(p_3)
    end
  end
end

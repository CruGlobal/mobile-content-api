# frozen_string_literal: true

require 'rails_helper'
require 'page_util'
require 'xml_util'

describe PageUtil do
  let(:locale) { 'de' }

  let(:filename_1) { 'test_page_1.xml' }
  let(:filename_2) { 'test_page_2.xml' }
  let(:id_1) { 1 }
  let(:id_2) { 2 }
  let(:phrase_1) { 'phrase 1' }
  let(:phrase_2) { 'phrase 2' }

  let(:structure_1) do
    "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<page xmlns=\"https://mobile-content-api.cru.org/xmlns/tract\"
      xmlns:content=\"https://mobile-content-api.cru.org/xmlns/content\">
  <hero>
    <heading>
      <content:text i18n-id=\"#{id_1}\">#{phrase_1}</content:text>
    </heading>

    <paragraph>
      <content:text i18n-id=\"#{id_2}\">#{phrase_2}</content:text>
    </paragraph>
  </hero>
</page>"
  end

  let(:structure_2) do
    "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<page xmlns=\"https://mobile-content-api.cru.org/xmlns/tract\"
      xmlns:content=\"https://mobile-content-api.cru.org/xmlns/content\">
  <hero>
    <heading>
      <content:text i18n-id=\"3\">phrase 3</content:text>
    </heading>
  </hero>
</page>"
  end

  let(:any_string) { /.*/ }

  let(:page_util_instance) do
    page_one = Page.new(filename: filename_1, structure: structure_1)
    page_two = Page.new(filename: filename_2, structure: structure_2)

    resource = Resource.new(pages: [page_one, page_two], onesky_project_id: 1)

    described_class.new(resource, locale)
  end

  before do
    allow(RestClient).to receive(:post)
  end

  it 'deletes all temp files after successful request' do
    page_util_instance.push_new_onesky_translation

    pages_dir = Dir.glob('pages/*')
    expect(pages_dir).to be_empty
  end

  it 'deletes all temp files if error is raised' do
    allow(RestClient).to receive(:post).and_raise(StandardError)

    expect { page_util_instance.push_new_onesky_translation }.to raise_error(StandardError)

    pages_dir = Dir.glob('pages/*')
    expect(pages_dir).to be_empty
  end

  context 'POSTS to OneSky' do
    let(:file_1) { double }
    let(:file_2) { double }
    let(:file_3) { double }

    before do
      allow(File).to receive(:new).with("pages/#{filename_1}").and_return(file_1)
      allow(File).to receive(:new).with("pages/#{filename_2}").and_return(file_2)
      allow(File).to receive(:new).with('pages/name_description.xml').and_return(file_3)
    end

    it 'correct URL' do
      url = 'https://platform.api.onesky.io/1/projects/1/files'

      page_util_instance.push_new_onesky_translation

      expect(RestClient).to have_received(:post).with(url, anything).exactly(3).times
    end

    it 'all resource pages' do
      page_util_instance.push_new_onesky_translation

      expect(RestClient).to have_received(:post).with(any_string, hash_including(file: file_1))
      expect(RestClient).to have_received(:post).with(any_string, hash_including(file: file_2))
    end

    it 'name/description file' do
      page_util_instance.push_new_onesky_translation

      expect(RestClient).to have_received(:post).with(any_string, hash_including(file: file_3))
    end

    it 'correct locale' do
      page_util_instance.push_new_onesky_translation

      expect(RestClient).to have_received(:post).with(any_string, hash_including(locale: locale)).exactly(3).times
    end

    it 'keeps existing strings by default' do
      page_util_instance.push_new_onesky_translation

      expect(RestClient).to(
        have_received(:post).with(any_string, hash_including(is_keeping_all_strings: true)).exactly(2).times
      )
    end
  end

  it 'writes all OneSky phrases to temp file' do
    allow(described_class).to receive(:delete_temp_pages)

    page_util_instance.push_new_onesky_translation

    file = File.new("pages/#{filename_1}")
    expect(file.read).to eq("{\"#{id_1}\":\"#{phrase_1}\",\"#{id_2}\":\"#{phrase_2}\"}")
  end
end

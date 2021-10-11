# frozen_string_literal: true

require "rails_helper"
require "page_client"
require "xml_util"

describe PageClient do
  let(:locale) { "de" }

  let(:name) { "resource name" }
  let(:description) { "resource description" }

  let(:filename_1) { "test_page_1.xml" }
  let(:filename_2) { "test_page_2.xml" }
  let(:id_1) { 1 }
  let(:id_2) { 2 }
  let(:phrase_1) { "phrase 1" }
  let(:phrase_2) { "phrase 2" }

  let(:structure_1) do
    "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<page xmlns=\"https://mobile-content-api.cru.org/xmlns/tract\"
      xmlns:content=\"https://mobile-content-api.cru.org/xmlns/content\">
  <hero>
    <heading>
      <content:text i18n-id=\"#{id_1}\">#{phrase_1}</content:text>
    </heading>

    <content:paragraph>
      <content:text i18n-id=\"#{id_2}\">#{phrase_2}</content:text>
    </content:paragraph>
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

  let(:resource) do
    pages = [Page.new(filename: filename_1, structure: structure_1, position: 1),
      Page.new(filename: filename_2, structure: structure_2, position: 2)]

    resource = Resource.create!(abbreviation: "test",
      onesky_project_id: 1,
      name: name,
      description: description,
      resource_type_id: 1,
      system_id: 1)
    resource.pages = pages
    resource
  end

  let(:page_client) do
    described_class.new(resource, locale)
  end

  before do
    allow(RestClient).to receive(:post)
  end

  it "deletes all temp files after successful request" do
    page_client.push_new_onesky_translation

    pages_dir = Dir.glob("pages/*")
    expect(pages_dir).to be_empty
  end

  it "deletes all temp files if error is raised" do
    allow(RestClient).to receive(:post).and_raise(StandardError)

    expect { page_client.push_new_onesky_translation }.to raise_error(StandardError)

    pages_dir = Dir.glob("pages/*")
    expect(pages_dir).to be_empty
  end

  context "POSTS to OneSky" do
    let(:file_1) { double }
    let(:file_2) { double }
    let(:file_3) { double }
    let(:file_4) { double }

    before do
      allow(File).to receive(:new).with("pages/#{filename_1}").and_return(file_1)
      allow(File).to receive(:new).with("pages/#{filename_2}").and_return(file_2)
      allow(File).to receive(:new).with("pages/name_description.xml").and_return(file_3)
      allow(File).to receive(:new).with("pages/attributes.xml").and_return(file_4)
    end

    it "correct URL" do
      url = "https://platform.api.onesky.io/1/projects/1/files"

      page_client.push_new_onesky_translation

      expect(RestClient).to have_received(:post).with(url, anything).exactly(4).times
    end

    it "all resource pages" do
      page_client.push_new_onesky_translation

      expect(RestClient).to have_received(:post).with(any_string, hash_including(file: file_1))
      expect(RestClient).to have_received(:post).with(any_string, hash_including(file: file_2))
    end

    context "translatable attributes" do
      it "resource uses OneSky" do
        page_client.push_new_onesky_translation

        expect(RestClient).to have_received(:post).with(any_string, hash_including(file: file_4))
      end

      it "resource does not use OneSky" do
        allow(resource).to receive(:uses_onesky?).and_return(false)

        page_client.push_new_onesky_translation

        expect(RestClient).not_to have_received(:post).with(any_string, hash_including(file: file_4))
      end
    end

    it "name/description file" do
      page_client.push_new_onesky_translation

      expect(RestClient).to have_received(:post).with(any_string, hash_including(file: file_3))
    end

    it "correct locale" do
      page_client.push_new_onesky_translation

      expect(RestClient).to have_received(:post).with(any_string, hash_including(locale: locale)).exactly(4).times
    end

    it "keeps existing strings by default" do
      page_client.push_new_onesky_translation

      expect(RestClient).to(
        have_received(:post).with(any_string, hash_including(is_keeping_all_strings: true)).exactly(3).times
      )
    end
  end

  context "temp files created with" do
    let!(:attr_1) { FactoryBot.create(:attribute, key: "roger", value: "test 1", resource: resource, is_translatable: true) }
    let!(:attr_2) { FactoryBot.create(:attribute, key: "thor", value: "test 2", resource: resource, is_translatable: true) }

    it "all OneSky phrases" do
      allow(described_class).to receive(:delete_temp_pages)

      page_client.push_new_onesky_translation

      file = File.new("pages/#{filename_1}")
      expect(JSON.parse(file.read)).to eq({id_1.to_s => phrase_1, id_2.to_s => phrase_2})
    end

    it "name and description" do
      allow(described_class).to receive(:delete_temp_pages)

      page_client.push_new_onesky_translation

      file = File.new("pages/name_description.xml")
      expect(JSON.parse(file.read)).to eq({"name" => name, "description" => description})
    end

    it "translatable attributes" do
      allow(described_class).to receive(:delete_temp_pages)

      page_client.push_new_onesky_translation

      file = File.new("pages/attributes.xml")
      expect(JSON.parse(file.read)).to eq({attr_1.key => attr_1.value, attr_2.key => attr_2.value})
    end
  end
end

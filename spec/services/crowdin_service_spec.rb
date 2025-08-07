# frozen_string_literal: true

require "rails_helper"

describe CrowdinService do
  describe ".download_translated_phrases" do
    let(:project_id) { 123 }
    let(:language_code) { "en" }
    let(:filename) { "sample.xml" }

    it "downloads translated phrases from Crowdin" do
      mock_client = double("Crowdin::Client")
      allow(CrowdinService).to receive(:client).and_return(mock_client)

      # Mock the language lookup
      language = double("Language", name: "English")
      allow(Language).to receive(:find_by).with(code: language_code).and_return(language)

      # Mock all_crowdin_languages_by_name
      languages_response = {
        "data" => [
          {"data" => {"name" => "English", "id" => "en"}}
        ]
      }
      allow(mock_client).to receive(:list_languages).with(limit: 100, offset: 0).and_return(languages_response)
      allow(mock_client).to receive(:list_languages).with(limit: 100, offset: 100).and_return({"data" => []})

      # Mock the export call
      export_response = {
        "data" => {
          "url" => "http://example.com/export.xml"
        }
      }
      allow(mock_client).to receive(:export_project_translation)
        .with({targetLanguageId: "en", format: "android"}, nil, project_id)
        .and_return(export_response)

      # Mock the HTTP request to the export URL
      xml_content = '<?xml version="1.0" encoding="UTF-8"?><resources><string name="test_key">translated_text</string></resources>'
      stub_request(:get, "http://example.com/export.xml")
        .to_return(status: 200, body: xml_content, headers: {})

      result = CrowdinService.download_translated_phrases(project_id: project_id, language_code: language_code)

      expect(result).to eq("test_key" => "translated_text")
    end

    it "handles errors gracefully" do
      mock_client = double("Crowdin::Client")
      allow(CrowdinService).to receive(:client).and_return(mock_client)
      allow(mock_client).to receive(:list_languages).and_raise(StandardError.new("API Error"))

      result = CrowdinService.download_translated_phrases(project_id: project_id, language_code: language_code)

      expect(result).to eq({})
    end

    it "builds the client" do
      expect(CrowdinService.client).to_not be_nil
    end
  end
end

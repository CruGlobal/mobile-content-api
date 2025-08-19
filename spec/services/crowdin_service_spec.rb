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

      # Use the seeded language
      language = Language.find_by!(code: language_code)
      # Ensure crowdin_code is set for the test
      language.update!(crowdin_code: "en")

      # Mock the export call
      export_response = {
        "data" => {
          "url" => "http://example.com/export.xml"
        }
      }
      allow(mock_client).to receive(:export_project_translation)
        .with({targetLanguageId: "en", format: "crowdin-json"}, nil, project_id)
        .and_return(export_response)

      # Mock the HTTP request to the export URL - crowdin-json format returns direct JSON
      json_content = '{"test_key":"translated_text"}'
      stub_request(:get, "http://example.com/export.xml")
        .to_return(status: 200, body: json_content, headers: {})

      result = CrowdinService.download_translated_phrases(project_id: project_id, language_code: language_code)

      expect(result).to eq("test_key" => "translated_text")
    end

    it "raises errors instead of handling them" do
      mock_client = double("Crowdin::Client")
      allow(CrowdinService).to receive(:client).and_return(mock_client)

      # Use the seeded language
      language = Language.find_by!(code: language_code)
      # Ensure crowdin_code is set for the test
      language.update!(crowdin_code: "en")

      allow(mock_client).to receive(:export_project_translation).and_raise(StandardError.new("API Error"))

      expect {
        CrowdinService.download_translated_phrases(project_id: project_id, language_code: language_code)
      }.to raise_error(StandardError, "API Error")
    end

    it "builds the client" do
      expect(CrowdinService.client).to_not be_nil
    end
  end
end

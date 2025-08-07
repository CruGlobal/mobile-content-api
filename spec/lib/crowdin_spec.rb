# frozen_string_literal: true

require "rails_helper"

describe Crowdin do
  describe ".download_translated_phrases" do
    let(:project_id) { 123 }
    let(:language_code) { "en" }
    let(:filename) { "sample.xml" }

    before do
      allow(ENV).to receive(:[]).with("CROWDIN_API_TOKEN").and_return("test_token")
      allow(ENV).to receive(:[]).with("CROWDIN_PROJECT_ID").and_return("123")
    end

    it "downloads translated phrases from Crowdin" do
      mock_client = double("Crowdin::Client")
      allow(Crowdin).to receive(:client).and_return(mock_client)
      
      mock_response = {
        "data" => [
          {
            "data" => {
              "string" => {
                "data" => {
                  "identifier" => "test_key",
                  "text" => "original_text"
                }
              },
              "text" => "translated_text"
            }
          }
        ]
      }
      
      allow(mock_client).to receive(:fetch_string_translations)
        .with(project_id, language_code: language_code)
        .and_return(mock_response)

      result = Crowdin.download_translated_phrases(filename, project_id: project_id, language_code: language_code)
      
      expect(result).to eq("test_key" => "translated_text")
    end

    it "handles errors gracefully" do
      mock_client = double("Crowdin::Client")
      allow(Crowdin).to receive(:client).and_return(mock_client)
      allow(mock_client).to receive(:fetch_string_translations).and_raise(StandardError.new("API Error"))

      result = Crowdin.download_translated_phrases(filename, project_id: project_id, language_code: language_code)
      
      expect(result).to eq({})
    end
  end
end
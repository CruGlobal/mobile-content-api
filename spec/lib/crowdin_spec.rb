# frozen_string_literal: true

require "rails_helper"

describe CrowdIn do
  let(:klass) do
    Class.new do
      include CrowdIn
      public :download_translated_phrases
    end
  end

  let(:target) { klass.new }
  let(:crowdin_client) { instance_double(Crowdin::Client) }
  let(:source_files_api) { instance_double("Crowdin::SourceFilesApi") }
  let(:translations_api) { instance_double("Crowdin::TranslationsApi") }
  let(:storages_api) { instance_double("Crowdin::StoragesApi") }

  before do
    allow(Crowdin::Client).to receive(:new).and_return(crowdin_client)
    allow(crowdin_client).to receive(:source_files).and_return(source_files_api)
    allow(crowdin_client).to receive(:translations).and_return(translations_api)
    allow(crowdin_client).to receive(:storages).and_return(storages_api)
  end

  it "downloads translated phrases" do
    file_data = {
      "data" => [
        {
          "data" => {
            "id" => 123,
            "name" => "sample.xml"
          }
        }
      ]
    }
    
    translation_data = {
      "data" => {
        "url" => "https://example.com/translation"
      }
    }
    
    allow(source_files_api).to receive(:list_files).with(123).and_return(file_data)
    allow(translations_api).to receive(:build_project_file_translation).with(
      123, 
      123, 
      { targetLanguageId: "en" }
    ).and_return(translation_data)
    
    expect(RestClient).to receive(:get).with("https://example.com/translation")
      .and_return(instance_double(RestClient::Response, body: '{ "foo": "bar" }'))

    result = target.download_translated_phrases "sample.xml", project_id: 123, language_code: "en"
    expect(result).to eql("foo" => "bar")
  end

  it "pushes phrases from a file" do
    file = File.open("spec/fixtures/sample.json")
    storage_data = { "data" => { "id" => 456 } }
    file_data = { "data" => [] } # No existing files
    
    allow(storages_api).to receive(:add_storage).with(file).and_return(storage_data)
    allow(source_files_api).to receive(:list_files).with(123).and_return(file_data)
    
    expect(source_files_api).to receive(:add_file).with(
      123,
      {
        "storageId" => 456,
        "name" => "sample.json",
        "title" => "sample",
        "type" => "json",
        "importOptions" => {
          "contentSegmentation" => true,
          "translateContent" => true,
          "translationReplace" => false
        }
      }
    )

    result = described_class.push_phrases file, project_id: 123, language_code: "en"
  end
  
  it "updates existing file" do
    file = File.open("spec/fixtures/sample.json")
    storage_data = { "data" => { "id" => 456 } }
    file_data = {
      "data" => [
        {
          "data" => {
            "id" => 789,
            "name" => "sample.json"
          }
        }
      ]
    }
    
    allow(storages_api).to receive(:add_storage).with(file).and_return(storage_data)
    allow(source_files_api).to receive(:list_files).with(123).and_return(file_data)
    
    expect(source_files_api).to receive(:update_file).with(
      123,
      789,
      { 
        "storageId" => 456,
        "updateOption" => "keep_translations"
      }
    )

    result = described_class.push_phrases file, project_id: 123, language_code: "en"
  end
end 
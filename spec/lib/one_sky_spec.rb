# frozen_string_literal: true

require "rails_helper"

describe OneSky do
  let(:klass) do
    Class.new do
      include OneSky
      public :download_translated_phrases
    end
  end

  let(:target) { klass.new }

  it "downloads translated phrases" do
    stub_request(:get, "https://platform.api.onesky.io/1/projects/123/translations")
      .with(query: hash_including("export_file_name" => "sample.xml",
        "source_file_name" => "sample.xml",
        "locale" => "en"))
      .to_return(status: 200, body: '{ "foo":"bar" }')

    result = target.download_translated_phrases "sample.xml", project_id: 123, language_code: "en"
    expect(result).to eql("foo" => "bar")
  end

  it "sets headers on translated phrase download" do
    url = "https://platform.api.onesky.io/1/projects/123/translations"
    headers = "api_key,dev_hash,timestamp,locale,export_file_name,source_file_name"
    stub_request(:get, Addressable::Template.new("#{url}{?#{headers}}"))
      .to_return(status: 200, body: "{}")

    result = target.download_translated_phrases "sample.xml", project_id: 123, language_code: "en"
    expect(result).to eql({})
  end

  it "pushes phrases from a file" do
    file = File.open("spec/fixtures/sample.json")
    stub_request(:post, "https://platform.api.onesky.io/1/projects/123/files")
      .to_return(status: 201)

    result = described_class.push_phrases file, project_id: 123, language_code: "en"
    expect(result.code).to be 201
  end
end

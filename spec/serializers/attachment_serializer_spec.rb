# frozen_string_literal: true

require "rails_helper"

RSpec.describe AttachmentSerializer, type: :serializer do
  include Rails.application.routes.url_helpers

  let(:test_file) { Rack::Test::UploadedFile.new("#{fixture_paths.first}/wall.jpg", "image/png") }
  let(:attachment) { Attachment.create(resource_id: 2, file: test_file) }

  subject { described_class.new(attachment) }

  describe "#file" do
    context "when CDN host is configured" do
      before { ENV["MOBILE_CONTENT_API_CDN_HOST"] = "cdn.example.com" }
      after { ENV.delete("MOBILE_CONTENT_API_CDN_HOST") }

      it "returns a CDN URL using the blob key" do
        url = subject.file
        expect(url).to start_with("https://cdn.example.com/")
        expect(url).to end_with(attachment.file.blob.key)
      end
    end

    context "when CDN host is not configured" do
      before { ENV.delete("MOBILE_CONTENT_API_CDN_HOST") }

      it "returns a standard blob URL" do
        url = subject.file
        expect(url).to include("/rails/active_storage/blobs/")
      end
    end
  end
end

# frozen_string_literal: true

require "acceptance_helper"

resource "Attachments" do
  let(:test_file) { Rack::Test::UploadedFile.new("#{fixture_path}/wall.jpg", "image/png") }
  let(:authorization) { AuthToken.create!(access_code: AccessCode.find(1)).token }

  before do
    allow_any_instance_of(Attachment).to receive(:url) do |attachment|
      ActiveStorage::Blob.service.send(:path_for, attachment.file.key)
    end
  end

  get "attachments/:id/download" do
    let(:id) { 1 }

    it "download an Attachment" do
      do_request

      expect(status).to be(302)
    end
  end

  post "attachments/" do
    before do
      header "Authorization", :authorization
    end

    requires_authorization

    it "create an Attachment" do
      do_request file: test_file, multipart: true, resource_id: 2

      expect(status).to be(204)
      expect(response_body).to be_empty
    end

    it "sets location header", document: false do
      do_request file: test_file, multipart: true, resource_id: 2

      expect(response_headers["Location"]).to match(%r{attachments/\d+})
    end
  end

  put "attachments/:id" do
    let(:id) { 1 }

    before do
      header "Authorization", :authorization
    end

    requires_authorization

    it "update an Attachment" do
      do_request file: test_file, multipart: true, resource_id: 2

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end

  delete "attachments/:id" do
    let(:id) { 1 }

    before do
      header "Authorization", :authorization
    end

    requires_authorization

    it "delete an Attachment" do
      do_request

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end

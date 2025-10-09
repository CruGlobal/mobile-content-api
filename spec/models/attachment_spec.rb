# frozen_string_literal: true

require "rails_helper"

describe Attachment do
  let(:test_file) { Rack::Test::UploadedFile.new("#{fixture_paths.first}/wall.jpg", "image/png") }

  before do
    allow_any_instance_of(described_class).to receive(:url) do |attachment|
      ActiveStorage::Blob.service.send(:path_for, attachment.file.key)
    end
  end

  it "is not zipped unless specified" do
    result = described_class.create(resource_id: 2, file: test_file)
    expect(result).to be_valid
    expect(result.is_zipped).to be_falsey
  end

  it "cannot duplicate file name and resource" do
    result = described_class.create(resource_id: 1, file: test_file)
    expect(result.errors[:file][1]).to include("filename is duplicate")
  end

  it "does not read sha when not updating file" do
    attachment = described_class.find(1)
    attachment.update(resource_id: 2)
    expect(attachment).to be_valid
  end

  context "sha256 is saved on" do
    it "create" do
      result = described_class.create(resource_id: 2, file: test_file)

      expect(result.sha256).to eq("073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd")
    end

    it "update" do
      attachment = described_class.find(1)
      attachment.update(resource_id: 2, file: Rack::Test::UploadedFile.new("#{fixture_paths.first}/beal.jpg", "image/png"))

      expect(attachment.sha256).to eq("398ddaf37848344632c44bd9c057b7e092e19f93c825f6bc4737f885f517a2ce")
    end
  end

  context "cannot have two attachments with the same sha256 for the same package" do
    it "creating" do
      result = described_class.create(resource_id: 1,
        file: Rack::Test::UploadedFile.new("#{fixture_paths.first}/wall_2.jpg", "image/png"))

      expect(result.errors["file"]).to include("This file already exists for this resource")
    end

    it "updating" do
      attachment = described_class.find(2)

      attachment.update(file: Rack::Test::UploadedFile.new("#{fixture_paths.first}/wall_2.jpg", "image/png"))

      expect(attachment.errors["file"]).to include("This file already exists for this resource")
    end
  end
end

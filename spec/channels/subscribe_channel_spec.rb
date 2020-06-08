require "rails_helper"
require "securerandom"

RSpec.describe SubscribeChannel, type: :channel do
  subject(:channel) { described_class.new(connection, {}) }

  before do
    stub_connection channelId: "12345"
    Rails.cache.clear
  end

  let(:setup_metadata) do
    Rails.cache.write([BaseSharingChannel::SUBSCRIBER_TO_PUBLISHER, "12345"], "99999")
    Rails.cache.write([BaseSharingChannel::METADATA_CACHE_PREFIX, "99999"], metadata)
  end

  context "active metadata" do
    let(:metadata) { {last_used_at: 119.minutes.ago, subscriber_channel_id: "12345"} }

    it "successfully subscribes" do
      setup_metadata
      subscribe(channelId: "12345")
      expect(transmissions.last).to be nil
    end
  end

  context "subscriber channel not found" do
    it "returns an error" do
      subscribe(channelId: "12345")
      expect(transmissions.last).to eq({"errors" => ["title" => "Channel Not Found"]})
    end
  end

  context "subscriber channel missing" do
    it "returns an error" do
      subscribe
      expect(transmissions.last).to eq({"errors" => ["title" => "Subscriber Channel Missing"]})
    end
  end

  context "subscriber channel has expired" do
    let(:metadata) { {last_used_at: 121.minutes.ago, subscriber_channel_id: "12345"} }

    it "returns an error" do
      setup_metadata
      subscribe(channelId: "12345")
      expect(transmissions.last).to eq({"errors" => ["title" => "Old Channel"]})
    end
  end
end

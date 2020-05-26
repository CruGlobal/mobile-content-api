require "rails_helper"
require 'securerandom'

RSpec.describe PublishChannel, type: :channel do
  subject(:channel) { described_class.new(connection, {}) }

  before do
    stub_connection channelId: '12345'
  end

  it "successfully subscribes" do
    uid = "#{SecureRandom.hex(10)}_#{Time.now.to_i}"
    expect_any_instance_of(PublishChannel).to receive(:new_random_uid).and_return(uid)

    subscribe(channelId: '12345')
    expect(subscription).to be_confirmed
    expect(transmissions.last).to eq("data" => { "type" => "publisher-info", "attributes" => { "subscriberChannelId" => uid }})
  end

  context "#publisher channel missing" do
    it "returns an error" do
      subscribe
      expect(transmissions.last).to eq({"errors" => ["title" => "Publisher Channel Missing"]})
    end
  end

  context "#publisher channel invalid format" do
    it "returns an error" do
      subscribe(channelId: '1')
      expect(transmissions.last).to eq({"errors" => ["title" => "Publisher Channel Invalid"]})
    end
  end

  context "#new_random_uid" do
    it "generates a uid based on time" do
			hex = SecureRandom.hex(10)
      expect(SecureRandom).to receive(:hex).with(10).and_return(hex)
      now = Time.now
      allow(Time).to receive(:now).and_return(now)
      expect(subject.send(:new_random_uid)).to eq("#{hex}_#{now.to_i}")
    end
  end

  it "re-uses subscriber id if connected before two hours is up" do
    uid = "#{SecureRandom.hex(10)}_#{Time.now.to_i}"
    allow_any_instance_of(PublishChannel).to receive(:new_random_uid).and_return(uid)

    metadata = { last_used_at: 119.minutes.ago, subscriber_channel_id: uid }
    Rails.cache.write(["sharing_metadata", "12345"], metadata)
    expect_any_instance_of(PublishChannel).to_not receive(:new_random_uid)

    subscribe(channelId: "12345")
    expect(subscription).to be_confirmed
    expect(transmissions.last).to eq({"data"=>{"attributes"=>{"subscriberChannelId"=>uid}, "type"=>"publisher-info"}})
  end

  it "resets subscriber id if connected after two hours is up" do
    old_uid = "#{SecureRandom.hex(10)}_#{Time.now.to_i}"
    new_uid = "#{SecureRandom.hex(10)}_#{Time.now.to_i}"
    allow_any_instance_of(PublishChannel).to receive(:new_random_uid).and_return(new_uid)

    metadata = { last_used_at: 121.minutes.ago, subscriber_channel_id: old_uid }
    Rails.cache.write(["sharing_metadata", "12345"], metadata)
    expect_any_instance_of(PublishChannel).to receive(:new_random_uid).and_return(new_uid)

    subscribe(channelId: '12345')
    expect(subscription).to be_confirmed
    expect(transmissions.last).to eq({"data"=>{"attributes"=>{"subscriberChannelId"=>new_uid}, "type"=>"publisher-info"}})
  end
end

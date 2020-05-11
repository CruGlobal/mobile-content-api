require "rails_helper"

RSpec.describe PublishChannel, type: :channel do
  before do
    # initialize connection with identifiers
    stub_connection channelId: '12345'
  end

  it "successfully subscribes" do
    subscribe
    expect(subscription).to be_confirmed
  end
end

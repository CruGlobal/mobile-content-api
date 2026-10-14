# frozen_string_literal: true

require "rails_helper"

describe UserInviteNotifier do
  let(:invite) { FactoryBot.build(:user_invite) }

  it "is disabled until a mail path exists" do
    expect(described_class.enabled?).to be false
  end

  it "queues nothing while disabled" do
    expect(described_class.deliver(invite)).to be false
  end

  it "reports a queued email once enabled" do
    allow(described_class).to receive(:enabled?).and_return(true)

    expect(described_class.deliver(invite)).to be true
  end
end

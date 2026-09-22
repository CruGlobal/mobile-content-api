# frozen_string_literal: true

require "rails_helper"

RSpec.describe MailchimpSubscribeJob, type: :job do
  let(:user) { FactoryBot.create(:user) }

  it "subscribes the user via the Mailchimp service" do
    expect(Mailchimp).to receive(:subscribe).with(user)

    MailchimpSubscribeJob.new.perform(user.id)
  end

  it "does nothing when the user no longer exists" do
    expect(Mailchimp).not_to receive(:subscribe)

    MailchimpSubscribeJob.new.perform(-1)
  end
end

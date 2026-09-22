# frozen_string_literal: true

require "rails_helper"

RSpec.describe MailchimpRemoveJob, type: :job do
  it "archives the email via the Mailchimp service by default" do
    expect(Mailchimp).to receive(:remove).with("diana@themyscira.pi", permanent: false)

    MailchimpRemoveJob.new.perform("diana@themyscira.pi")
  end

  it "permanently deletes the email when the permanent flag is set" do
    expect(Mailchimp).to receive(:remove).with("diana@themyscira.pi", permanent: true)

    MailchimpRemoveJob.new.perform("diana@themyscira.pi", true)
  end
end

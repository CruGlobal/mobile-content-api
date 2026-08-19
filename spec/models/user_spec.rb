require "rails_helper"
require "sidekiq/testing"

RSpec.describe User, type: :model do
  before do
    MailchimpSubscribeJob.clear
    MailchimpRemoveJob.clear
  end

  describe "mailchimp callbacks" do
    it "queues a MailchimpSubscribeJob when a user is created" do
      user = FactoryBot.create(:user)

      expect(MailchimpSubscribeJob.jobs.map { |job| job["args"] }).to eq([[user.id]])
    end

    it "does not queue a MailchimpSubscribeJob when a user is updated" do
      user = FactoryBot.create(:user)
      MailchimpSubscribeJob.clear

      user.update!(first_name: "Updated")

      expect(MailchimpSubscribeJob.jobs).to be_empty
    end

    it "queues a MailchimpRemoveJob with the user's email when a user is destroyed" do
      user = FactoryBot.create(:user)

      user.destroy!

      expect(MailchimpRemoveJob.jobs.map { |job| job["args"] }).to eq([[user.email]])
    end
  end
end

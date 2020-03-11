# frozen_string_literal: true

require "rails_helper"

Adobe::Campaign.configure do |config|
  config.org_id = ENV["ADOBE_CAMPAIGN_ORG_ID"]
  config.org_name = ENV["ADOBE_CAMPAIGN_ORG_NAME"]
  config.tech_acct = ENV["ADOBE_CAMPAIGN_TECH_ACCT"]
  config.signed_jwt = ENV["ADOBE_CAMPAIGN_SIGNED_JWT"]
  config.api_key = "dummy_api_key"
  config.api_secret = "dummy_api_secret"
end

describe AdobeCampaign do
  include AdobeCampaignStubHelpers

  describe "#subscribe!" do
    subject { described_class.new(follow_up).subscribe! }

    let(:destination) { Destination.adobe_campaigns.first! }
    let(:language) { Language.find_by!(code: "en") }
    let(:mapped_language_code) { Adobe::Campaign::Language.map_code(language.code) }

    let(:email) { "carlos.kozuszko@example.com" }
    let(:follow_up_valid_attrs) { {email: email, name: "Carlos Kozuszko", destination_id: destination.id, language_id: language.id} }
    let(:follow_up) { FollowUp.create!(follow_up_valid_attrs) }

    context "profile does not exist on adobe" do
      let(:profile_hash) {
        {email: email,
         firstName: "Carlos",
         lastName: "Kozuszko",
         preferredLanguage: mapped_language_code,}
      }
      it "creates profile and subscription" do
        stub_create_a_new_subscription_example(profile_hash, destination.service_name)
        subject
      end
    end
    context "there is an existing campaign" do
      it "creates subscription" do
        stub_find_an_existing_subscription_example(destination.service_name)
        subject
      end
    end
  end
end

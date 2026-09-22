# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mailchimp do
  let(:api_key) { "dummykey-us5" }
  let(:list_id) { "list123abc" }
  let(:email) { "Diana@Themyscira.pi" }
  let(:subscriber_hash) { Digest::MD5.hexdigest(email.downcase) }
  let(:member_url) { "https://us5.api.mailchimp.com/3.0/lists/#{list_id}/members/#{subscriber_hash}" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("MAILCHIMP_API_KEY").and_return(api_key)
    allow(ENV).to receive(:[]).with("MAILCHIMP_LIST_ID").and_return(list_id)
  end

  describe ".subscribe" do
    let(:user) { FactoryBot.create(:user, email: email) }

    it "upserts the user as a subscribed member of the list" do
      stub = stub_request(:put, member_url)
        .with(body: hash_including(
          "email_address" => email,
          "status_if_new" => "subscribed",
          "merge_fields" => {"FNAME" => user.first_name, "LNAME" => user.last_name}
        ))
        .to_return(status: 200, body: "{}", headers: {"Content-Type" => "application/json"})

      described_class.subscribe(user)

      expect(stub).to have_been_requested
    end

    it "omits blank merge fields" do
      user.update!(first_name: nil, last_name: "Woman")

      stub = stub_request(:put, member_url)
        .with(body: hash_including("merge_fields" => {"LNAME" => "Woman"}))
        .to_return(status: 200, body: "{}", headers: {"Content-Type" => "application/json"})

      described_class.subscribe(user)

      expect(stub).to have_been_requested
    end

    context "when mailchimp is not configured" do
      let(:api_key) { nil }

      it "does nothing" do
        described_class.subscribe(user)

        expect(WebMock).not_to have_requested(:any, /mailchimp/)
      end
    end
  end

  describe ".remove" do
    it "archives the list member" do
      stub = stub_request(:delete, member_url).to_return(status: 204)

      described_class.remove(email)

      expect(stub).to have_been_requested
    end

    it "permanently deletes the list member when permanent is true" do
      stub = stub_request(:post, "#{member_url}/actions/delete-permanent").to_return(status: 204)

      described_class.remove(email, permanent: true)

      expect(stub).to have_been_requested
    end

    it "treats a missing member as success" do
      stub_request(:delete, member_url).to_return(status: 404, body: "{}", headers: {"Content-Type" => "application/json"})

      expect { described_class.remove(email) }.not_to raise_error
    end

    it "raises on other API errors so the job can retry" do
      stub_request(:delete, member_url).to_return(status: 500, body: "{}", headers: {"Content-Type" => "application/json"})

      expect { described_class.remove(email) }.to raise_error(Gibbon::MailChimpError)
    end

    context "when mailchimp is not configured" do
      let(:list_id) { nil }

      it "does nothing" do
        described_class.remove(email)

        expect(WebMock).not_to have_requested(:any, /mailchimp/)
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe SalesforceService do
  let(:email) { "test@example.com" }
  let(:campaign_name) { "Test Campaign" }
  let(:data) { {first_name: "John", last_name: "Doe"} }
  let(:access_token) { "fake_access_token" }

  describe ".get_access_token" do
    context "when successful" do
      it "returns access token" do
        response_body = {"access_token" => access_token}.to_json
        response = instance_double(RestClient::Response, body: response_body)

        expect(RestClient).to receive(:post).and_return(response)
        expect(Rails.cache).to receive(:fetch).with("salesforce_access_token", expires_in: 20.minutes).and_yield

        result = described_class.get_access_token

        expect(result).to eq(access_token)
      end
    end

    context "when request fails" do
      it "logs error and returns nil" do
        error = RestClient::Exception.new("Connection failed")

        expect(RestClient).to receive(:post).and_raise(error)
        expect(Rails.logger).to receive(:error).with("Failed to get Salesforce access token: RestClient::Exception")
        expect(Rails.cache).to receive(:fetch).and_yield

        result = described_class.get_access_token

        expect(result).to be_nil
      end
    end
  end

  describe ".send_campaign_subscription" do
    context "when successful" do
      before do
        allow(described_class).to receive(:get_access_token).and_return(access_token)
      end

      it "sends campaign subscription and returns true" do
        response = instance_double(RestClient::Response, code: 200, body: "", headers: {})

        expect(RestClient).to receive(:post).and_return(response)
        allow(Rails.logger).to receive(:info)

        result = described_class.send_campaign_subscription(email, campaign_name, data)

        expect(result).to be true
      end

      it "sends correct payload to Salesforce" do
        response = instance_double(RestClient::Response, code: 200, body: "", headers: {})
        expected_payload = [
          {
            keys: {
              subscriberkey: email,
              campaign: campaign_name
            },
            values: {
              subscriberkey: email,
              campaign: campaign_name,
              email_address: email,
              first_name: "John",
              last_name: "Doe"
            }
          }
        ]
        expected_headers = {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
        expected_url = "https://api.salesforce.com/hub/v1/dataevents/key:external_key/rowset"

        expect(RestClient).to receive(:post).with(
          expected_url,
          expected_payload.to_json,
          expected_headers
        ).and_return(response)
        allow(Rails.logger).to receive(:info)

        described_class.send_campaign_subscription(email, campaign_name, data)
      end
    end

    context "when access token is nil" do
      it "returns false" do
        allow(described_class).to receive(:get_access_token).and_return(nil)

        result = described_class.send_campaign_subscription(email, campaign_name, data)

        expect(result).to be false
      end
    end

    context "when request fails" do
      before do
        allow(described_class).to receive(:get_access_token).and_return(access_token)
      end

      it "logs error and raises exception" do
        error = RestClient::Exception.new("Request failed")

        expect(RestClient).to receive(:post).and_raise(error)
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:error).with(/Failed to send campaign data to Salesforce/)

        expect {
          described_class.send_campaign_subscription(email, campaign_name, data)
        }.to raise_error(RestClient::Exception)
      end
    end
  end
end

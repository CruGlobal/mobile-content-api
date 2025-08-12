# frozen_string_literal: true

require "rails_helper"

describe SalesforceService do
  let(:email) { "test@example.com" }
  let(:campaign_name) { "Test Campaign" }
  let(:data) { {first_name: "John", last_name: "Doe"} }
  let(:access_token) { "fake_access_token" }
  let(:language) { Language.find(2) }
  let(:salesforce_destination) { Destination.salesforce.first! }
  let(:follow_up) do
    FollowUp.create!(
      email: email,
      name: "John Doe",
      language: language,
      destination: salesforce_destination
    )
  end

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


  describe "#initialize" do
    it "sets follow_up attribute" do
      service = described_class.new(follow_up)

      expect(service.follow_up).to eq(follow_up)
    end
  end

  describe "#subscribe!" do
    let(:service) { described_class.new(follow_up) }

    context "when successful" do
      before do
        allow(described_class).to receive(:get_access_token).and_return(access_token)
      end

      it "sends campaign subscription and completes successfully" do
        response = instance_double(RestClient::Response, code: 200, body: "", headers: {})

        expect(RestClient).to receive(:post).and_return(response)
        allow(Rails.logger).to receive(:info)

        expect { service.subscribe! }.not_to raise_error
      end

      it "sends correct payload to Salesforce" do
        response = instance_double(RestClient::Response, code: 200, body: "", headers: {})
        expected_payload = [
          {
            keys: {
              subscriberkey: email,
              campaign: salesforce_destination.service_name
            },
            values: {
              subscriberkey: email,
              campaign: salesforce_destination.service_name,
              email_address: email,
              first_name: "John",
              last_name: "Doe",
              language_code: language.code
            }
          }
        ]
        expected_headers = {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
        expected_url = "#{ENV.fetch("SALESFORCE_REST_URI")}/hub/v1/dataevents/key:#{ENV.fetch("SALESFORCE_SFMC_DE_EXTERNAL_KEY")}/rowset"

        expect(RestClient).to receive(:post).with(
          expected_url,
          expected_payload.to_json,
          expected_headers
        ).and_return(response)
        allow(Rails.logger).to receive(:info)

        service.subscribe!
      end
    end

    context "when access token is nil" do
      it "returns false without making request" do
        allow(described_class).to receive(:get_access_token).and_return(nil)

        result = service.subscribe!

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
          service.subscribe!
        }.to raise_error(RestClient::Exception)
      end
    end

    context "when response code is not 200" do
      before do
        allow(described_class).to receive(:get_access_token).and_return(access_token)
      end

      it "raises Error::BadRequestError" do
        response = instance_double(RestClient::Response, code: 400, body: "", headers: {})

        expect(RestClient).to receive(:post).and_return(response)
        allow(Rails.logger).to receive(:info)

        expect { service.subscribe! }.to raise_error(
          Error::BadRequestError,
          "Failed to send campaign subscription to Salesforce for email: #{email}"
        )
      end
    end

    context "when follow_up has no name" do
      let(:follow_up_without_name) do
        FollowUp.create!(
          email: email,
          name: nil,
          language: language,
          destination: salesforce_destination
        )
      end
      let(:service) { described_class.new(follow_up_without_name) }

      before do
        allow(described_class).to receive(:get_access_token).and_return(access_token)
      end

      it "sends compact data without name fields" do
        response = instance_double(RestClient::Response, code: 200, body: "", headers: {})
        expected_payload = [
          {
            keys: {
              subscriberkey: email,
              campaign: salesforce_destination.service_name
            },
            values: {
              subscriberkey: email,
              campaign: salesforce_destination.service_name,
              email_address: email,
              language_code: language.code
            }
          }
        ]
        expected_headers = {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
        expected_url = "#{ENV.fetch("SALESFORCE_REST_URI")}/hub/v1/dataevents/key:#{ENV.fetch("SALESFORCE_SFMC_DE_EXTERNAL_KEY")}/rowset"

        expect(RestClient).to receive(:post).with(
          expected_url,
          expected_payload.to_json,
          expected_headers
        ).and_return(response)
        allow(Rails.logger).to receive(:info)

        service.subscribe!
      end
    end
  end
end

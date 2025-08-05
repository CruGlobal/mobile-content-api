# frozen_string_literal: true

require "rails_helper"
require "validates_email_format_of/rspec_matcher"

describe FollowUp do
  let(:growth_space_destination) { Destination.growth_spaces.first! }
  let(:adobe_campaigns_destination) { Destination.adobe_campaigns.first! }
  let(:salesforce_destination) { Destination.salesforce.first! }
  let(:email) { "bob@test.org" }
  let(:language) { Language.find(2) }
  let(:language_id) { 3 }
  let(:first_name) { "Bob" }
  let(:last_name) { "Test" }
  let(:full_name) { "#{first_name} #{last_name}" }

  it "validates email address" do
    result = described_class
      .create(email: "myemail", language_id: language.id, destination_id: growth_space_destination.id, name: full_name)

    expect(result.errors[:email]).to include("Invalid email address")
  end

  describe "#send_to_api" do
    context "sends correct values to api" do
      let(:follow_up) { described_class.create(valid_attrs) }

      context "for service_type growth_spaces" do
        let(:destination) { growth_space_destination }

        before do
          mock_rest_client(201)
        end

        it "returns remote response code if request failed" do
          code = 404
          follow_up = described_class.create(valid_attrs)
          mock_rest_client(code)

          expect { follow_up.send_to_api }
            .to raise_error("Received response code: #{code} from destination: #{destination.id}")
        end

        it "ensures record is saved before sending to destination" do
          mock_rest_client(201)
          follow_up = described_class.new(valid_attrs)
          allow(follow_up).to receive(:save!)

          follow_up.send_to_api

          expect(follow_up).to have_received(:save!)
        end

        it "url" do
          follow_up.send_to_api

          expect(RestClient).to have_received(:post).with(destination.url, anything, anything)
        end

        it "body" do
          expected = {access_id: destination.access_key_id, access_secret: destination.access_key_secret,
                      subscriber: {route_id: destination.route_id, language_code: language.code, email: email,
                                   first_name: first_name, last_name: last_name}}.to_query

          follow_up.send_to_api

          expect(RestClient).to have_received(:post).with(any_string, expected, anything)
        end
      end

      context "for service_type adobe_campaigns" do
        let(:destination) { adobe_campaigns_destination }
        let(:service) { instance_double("AdobeCampaign") }

        it "delegates subscription to service class" do
          expect(AdobeCampaign).to receive(:new).with(follow_up).and_return(service)
          expect(service).to receive(:subscribe!)
          follow_up.send_to_api
        end
      end

      context "for service_type salesforce" do
        let(:destination) { salesforce_destination }

        before do
          allow(SalesforceService).to receive(:send_campaign_subscription).and_return(true)
        end

        it "calls SalesforceService with correct parameters" do
          expected_data = {
            email_address: email,
            first_name: first_name,
            last_name: last_name,
            language_code: language.code
          }

          follow_up.send_to_api

          expect(SalesforceService).to have_received(:send_campaign_subscription).with(
            email,
            destination.service_name,
            expected_data
          )
        end

        it "raises error when SalesforceService fails" do
          allow(SalesforceService).to receive(:send_campaign_subscription).and_return(false)

          expect { follow_up.send_to_api }.to raise_error(
            Error::BadRequestError,
            "Failed to send campaign subscription to Salesforce for email: #{email}"
          )
        end

        it "handles follow_up without name" do
          follow_up_without_name = described_class.create(
            email: email,
            language_id: language.id,
            destination_id: destination.id,
            name: nil
          )
          expected_data = {
            email_address: email,
            language_code: language.code
          }

          follow_up_without_name.send_to_api

          expect(SalesforceService).to have_received(:send_campaign_subscription).with(
            email,
            destination.service_name,
            expected_data
          )
        end
      end
    end
  end

  private

  def valid_attrs
    {email: email, language_id: language.id, destination_id: destination.id, name: full_name}
  end

  def mock_rest_client(code)
    allow(RestClient).to(
      receive(:post).and_return(double.as_null_object).and_return(instance_double(RestClient::Response, code: code))
    )
  end
end

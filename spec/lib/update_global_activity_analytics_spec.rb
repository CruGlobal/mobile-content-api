# frozen_string_literal: true

require "rails_helper"

describe UpdateGlobalActivityAnalytics do
  subject(:operation) { described_class.new }

  describe "#perform" do
    let(:response_status) { 200 }
    let(:access_token_status) { 200 }
    let(:last_update_time) { 1.second.before(GlobalActivityAnalytics::TTL.ago) }
    let(:counters) {
      proc {
        [
          GlobalActivityAnalytics.instance.users,
          GlobalActivityAnalytics.instance.countries,
          GlobalActivityAnalytics.instance.launches,
          GlobalActivityAnalytics.instance.gospel_presentations
        ]
      }
    }

    before do
      GlobalActivityAnalytics.instance.update!(updated_at: last_update_time)
      TestHelpers.stub_request_to_analytics(self, analytics_status: response_status, access_token_status: access_token_status)
    end

    context "when analytics is outdated" do
      context "when response is successful" do
        it "updates counters" do
          expect { operation.perform }.to change(&counters).from([0, 0, 0, 0]).to([238326, 6, 966442, 43834])
        end
      end

      context "when there is an error" do
        let(:response_status) { 400 }

        it "raises exception" do
          expect { operation.perform }.to raise_error(StandardError)
        end
      end
    end

    context "when analytics is up to date" do
      let(:last_update_time) { 1.second.ago }

      it "does not change counters" do
        expect { operation.perform }.not_to change(&counters).from([0, 0, 0, 0])
      end
    end

    context "when access token API fails" do
      let(:access_token_status) { 400 }

      it "raises exception" do
        expect { operation.perform }.to raise_error(StandardError)
      end
    end
  end

  describe "config file" do
    it "exists" do
      expect(File.exist?(described_class::SERVICE_ACCOUNT_CREDENTIALS_FILE_PATH)).to be(true),
        "Service credential file doesn't exist. If you want a dummy file run "\
        "`cp spec/fixtures/service_account_cred.json.travis #{described_class::SERVICE_ACCOUNT_CREDENTIALS_FILE_PATH}`"
    end
  end
end

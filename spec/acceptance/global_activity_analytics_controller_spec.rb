require "acceptance_helper"

resource "GlobalActivityAnalytics" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:analytics_status) { 200 }

  before { TestHelpers.stub_request_to_analytics(self, analytics_status: analytics_status) }

  get "/analytics/global" do
    let(:last_update_time) { 1.second.after(GlobalActivityAnalytics::TTL.ago) }

    before { GlobalActivityAnalytics.instance.update!(updated_at: last_update_time) }

    context "when statistics is up to date" do
      it "returns the statistics without updates" do
        do_request

        expect(status).to be(200)
        data = JSON.parse(response_body)["data"]
        expect(data["type"]).to eq("global-activity-analytics")
        expect(data["id"]).to eq("1")
        expect(data["attributes"]["users"]).to eq(0)
        expect(data["attributes"]["countries"]).to eq(0)
        expect(data["attributes"]["launches"]).to eq(0)
        expect(data["attributes"]["gospel-presentations"]).to eq(0)
      end
    end

    context "when statistics is outdated" do
      let(:last_update_time) { 1.second.before(GlobalActivityAnalytics::TTL.ago) }

      it "updates and returns the statistics" do
        do_request

        expect(status).to be(200)
        data = JSON.parse(response_body)["data"]
        expect(data["type"]).to eq("global-activity-analytics")
        expect(data["id"]).to eq("1")
        expect(data["attributes"]["users"]).to eq(238326)
        expect(data["attributes"]["countries"]).to eq(6)
        expect(data["attributes"]["launches"]).to eq(966442)
        expect(data["attributes"]["gospel-presentations"]).to eq(43834)
      end
    end

    context "when analytics API fails" do
      let(:last_update_time) { 1.second.before(GlobalActivityAnalytics::TTL.ago) }
      let(:analytics_status) { 400 }

      it "sends error to Rollbar but returns the cached result" do
        do_request

        expect(status).to be(200)
        data = JSON.parse(response_body)["data"]
        expect(data["type"]).to eq("global-activity-analytics")
        expect(data["id"]).to eq("1")
        expect(data["attributes"]["users"]).to eq(0)
        expect(data["attributes"]["countries"]).to eq(0)
        expect(data["attributes"]["launches"]).to eq(0)
        expect(data["attributes"]["gospel-presentations"]).to eq(0)
      end
    end
  end
end

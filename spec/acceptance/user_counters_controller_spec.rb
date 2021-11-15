# frozen_string_literal: true

require "acceptance_helper"

resource "UserCounters" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }
  let(:resource) { Resource.first }
  let(:resource2) { Resource.second }

  let(:structure) { FactoryBot.attributes_for(:user_counter)[:structure] }

  before do
  end

  patch "user/counters/:id" do
    let(:id) { "tool_opens.kgp" }
    let(:user) { FactoryBot.create(:user) }
    requires_okta_authorization

    it "create user_counter" do
      expect {
        do_request data: {type: "user_counter", attributes: {increment: 20}}
      }.to change { UserCounter.count }.by(1)

      expect(status).to eq(200)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
      expect(UserCounter.last.counter_name).to eq("tool_opens.kgp")
      expect(UserCounter.last.count).to eq(20)
    end

    context "when user_counter exists" do
      let!(:user_counter) { FactoryBot.create(:user_counter, user: user, counter_name: "tool_opens.kgp", count: 4) }

      it "updates the count" do
        expect {
          do_request data: {type: "user_counter", attributes: {increment: 20}}
        }.to_not change { user_counter.count }

        expect(status).to eq(200)
        expect(JSON.parse(response_body)["data"]).not_to be_nil
        expect(UserCounter.last.count).to eq(24)
      end
    end
  end
end

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

  patch "user/me/counters/:id" do
    let(:id) { "tool_opens.kgp" }
    let(:user) { FactoryBot.create(:user) }
    requires_okta_login

    it "create user_counter" do
      expect {
        do_request data: {type: "user_counter", attributes: {increment: 20}}
      }.to change { UserCounter.count }.by(1)

      expect(status).to eq(200)
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).not_to be_nil
      expect(json_response["id"]).to eq("tool_opens.kgp")
      expect(json_response["attributes"]["count"]).to eq(20)
      expect(json_response["attributes"]["decayed-count"]).to eq(20)
      expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
      expect(UserCounter.last.counter_name).to eq("tool_opens.kgp")
      expect(UserCounter.last.count).to eq(20)
      expect(UserCounter.last.decayed_count).to eq(20)
      expect(UserCounter.last.last_decay).to eq(Date.today)
    end

    context "when user_counter exists" do
      let!(:user_counter) { FactoryBot.create(:user_counter, user: user, counter_name: "tool_opens.kgp", count: 50, decayed_count: 50, last_decay: 90.days.ago) }

      it "updates the count and decay" do
        expect {
          do_request data: {type: "user_counter", attributes: {increment: 20}}
        }.to_not change { user_counter.count }

        expect(status).to eq(200)
        json_response = JSON.parse(response_body)["data"]
        expect(json_response).not_to be_nil
        expect(json_response["id"]).to eq("tool_opens.kgp")
        expect(json_response["attributes"]["count"]).to eq(70)
        expect((json_response["attributes"]["decayed-count"] - 45).abs).to be <= 0.004 # look within 0.004, close enough
        expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
        expect(UserCounter.last.count).to eq(70)
        # get close to 45 -- original value of 50 should decay to 25 with the 90 day half-life, then +20 from the patch count incremement
        expect((UserCounter.last.decayed_count - 45).abs).to be <= 0.004
        expect(UserCounter.last.last_decay).to eq(Date.today)
      end
    end
  end

  patch "user/counters/:id" do
    let(:id) { "tool_opens.kgp" }
    let(:user) { FactoryBot.create(:user) }
    requires_okta_login

    it "create user_counter" do
      expect {
        do_request data: {type: "user_counter", attributes: {increment: 20}}
      }.to change { UserCounter.count }.by(1)

      expect(status).to eq(200)
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).not_to be_nil
      expect(json_response["id"]).to eq("tool_opens.kgp")
      expect(json_response["attributes"]["count"]).to eq(20)
      expect(json_response["attributes"]["decayed-count"]).to eq(20)
      expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
      expect(UserCounter.last.counter_name).to eq("tool_opens.kgp")
      expect(UserCounter.last.count).to eq(20)
      expect(UserCounter.last.decayed_count).to eq(20)
      expect(UserCounter.last.last_decay).to eq(Date.today)
    end

    context "when user_counter exists" do
      let!(:user_counter) { FactoryBot.create(:user_counter, user: user, counter_name: "tool_opens.kgp", count: 50, decayed_count: 50, last_decay: 90.days.ago) }

      it "updates the count and decay" do
        expect {
          do_request data: {type: "user_counter", attributes: {increment: 20}}
        }.to_not change { user_counter.count }

        expect(status).to eq(200)
        json_response = JSON.parse(response_body)["data"]
        expect(json_response).not_to be_nil
        expect(json_response["id"]).to eq("tool_opens.kgp")
        expect(json_response["attributes"]["count"]).to eq(70)
        expect((json_response["attributes"]["decayed-count"] - 45).abs).to be <= 0.004 # look within 0.004, close enough
        expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
        expect(UserCounter.last.count).to eq(70)
        # get close to 45 -- original value of 50 should decay to 25 with the 90 day half-life, then +20 from the patch count incremement
        expect((UserCounter.last.decayed_count - 45).abs).to be <= 0.004
        expect(UserCounter.last.last_decay).to eq(Date.today)
      end
    end
  end

  patch "users/:user_id/counters/:id" do
    let(:id) { "tool_opens.kgp" }
    let(:user) { FactoryBot.create(:user) }
    let(:user_id) { user.id }
    requires_okta_login

    it "create user_counter" do
      expect {
        do_request data: {type: "user_counter", attributes: {increment: 20}}
      }.to change { UserCounter.count }.by(1)

      expect(status).to eq(200)
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).not_to be_nil
      expect(json_response["id"]).to eq("tool_opens.kgp")
      expect(json_response["attributes"]["count"]).to eq(20)
      expect(json_response["attributes"]["decayed-count"]).to eq(20)
      expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
      expect(UserCounter.last.counter_name).to eq("tool_opens.kgp")
      expect(UserCounter.last.count).to eq(20)
      expect(UserCounter.last.decayed_count).to eq(20)
      expect(UserCounter.last.last_decay).to eq(Date.today)
    end

    context "when user_counter exists" do
      let!(:user_counter) { FactoryBot.create(:user_counter, user: user, counter_name: "tool_opens.kgp", count: 50, decayed_count: 50, last_decay: 90.days.ago) }

      it "updates the count and decay" do
        expect {
          do_request data: {type: "user_counter", attributes: {increment: 20}}
        }.to_not change { user_counter.count }

        expect(status).to eq(200)
        json_response = JSON.parse(response_body)["data"]
        expect(json_response).not_to be_nil
        expect(json_response["id"]).to eq("tool_opens.kgp")
        expect(json_response["attributes"]["count"]).to eq(70)
        expect((json_response["attributes"]["decayed-count"] - 45).abs).to be <= 0.004 # look within 0.004, close enough
        expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
        expect(UserCounter.last.count).to eq(70)
        # get close to 45 -- original value of 50 should decay to 25 with the 90 day half-life, then +20 from the patch count incremement
        expect((UserCounter.last.decayed_count - 45).abs).to be <= 0.004
        expect(UserCounter.last.last_decay).to eq(Date.today)
      end
    end
  end

  get "users/:user_id/counters" do
    let(:user) { FactoryBot.create(:user) }
    let(:user_id) { user.id }
    let!(:user_counter) { FactoryBot.create(:user_counter, user: user, counter_name: "tool_opens.kgp", count: 50, decayed_count: 50, last_decay: 90.days.ago) }
    let!(:user_counter2) { FactoryBot.create(:user_counter, user: user, counter_name: "other.kgp", count: 60, decayed_count: 40, last_decay: 90.days.ago) }
    requires_okta_login

    it "gets counts" do
      do_request

      expect(status).to eq(200)
      today = Date.today.to_s
      expected_result = %({"data":[{"id":"tool_opens.kgp","type":"user-counter","attributes":{"count":50,"decayed-count":25.00367978478838,"last-decay":"#{today}"}},{"id":"other.kgp","type":"user-counter","attributes":{"count":60,"decayed-count":20.002943827830705,"last-decay":"#{today}"}}]})
      expect(response_body).to eq(expected_result)
    end
  end

  patch "users/:user_id/counters/:id" do
    let(:id) { "tool_opens.kgp" }
    let(:user) { FactoryBot.create(:user) }
    let(:user_id) { user.id }
    requires_okta_login

    it "create user_counter" do
      expect {
        do_request data: {type: "user_counter", attributes: {increment: 20}}
      }.to change { UserCounter.count }.by(1)

      expect(status).to eq(200)
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).not_to be_nil
      expect(json_response["id"]).to eq("tool_opens.kgp")
      expect(json_response["attributes"]["count"]).to eq(20)
      expect(json_response["attributes"]["decayed-count"]).to eq(20)
      expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
      expect(UserCounter.last.counter_name).to eq("tool_opens.kgp")
      expect(UserCounter.last.count).to eq(20)
      expect(UserCounter.last.decayed_count).to eq(20)
      expect(UserCounter.last.last_decay).to eq(Date.today)
    end

    context "when user_counter exists" do
      let!(:user_counter) { FactoryBot.create(:user_counter, user: user, counter_name: "tool_opens.kgp", count: 50, decayed_count: 50, last_decay: 90.days.ago) }

      it "updates the count and decay" do
        expect {
          do_request data: {type: "user_counter", attributes: {increment: 20}}
        }.to_not change { user_counter.count }

        expect(status).to eq(200)
        json_response = JSON.parse(response_body)["data"]
        expect(json_response).not_to be_nil
        expect(json_response["id"]).to eq("tool_opens.kgp")
        expect(json_response["attributes"]["count"]).to eq(70)
        expect((json_response["attributes"]["decayed-count"] - 45).abs).to be <= 0.004 # look within 0.004, close enough
        expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
        expect(UserCounter.last.count).to eq(70)
        # get close to 45 -- original value of 50 should decay to 25 with the 90 day half-life, then +20 from the patch count incremement
        expect((UserCounter.last.decayed_count - 45).abs).to be <= 0.004
        expect(UserCounter.last.last_decay).to eq(Date.today)
      end
    end
  end
end

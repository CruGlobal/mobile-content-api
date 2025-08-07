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
        expect((json_response["attributes"]["decayed-count"] - 45).abs).to be <= 0.5 # look within 0.5, close enough for timing differences
        expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
        expect(UserCounter.last.count).to eq(70)
        # get close to 45 -- original value of 50 should decay to 25 with the 90 day half-life, then +20 from the patch count incremement
        expect((UserCounter.last.decayed_count - 45).abs).to be <= 0.5
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
        expect((json_response["attributes"]["decayed-count"] - 45).abs).to be <= 0.5 # look within 0.5, close enough for timing differences
        expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
        expect(UserCounter.last.count).to eq(70)
        # get close to 45 -- original value of 50 should decay to 25 with the 90 day half-life, then +20 from the patch count incremement
        expect((UserCounter.last.decayed_count - 45).abs).to be <= 0.5
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
        expect((json_response["attributes"]["decayed-count"] - 45).abs).to be <= 0.5 # look within 0.5, close enough for timing differences
        expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
        expect(UserCounter.last.count).to eq(70)
        # get close to 45 -- original value of 50 should decay to 25 with the 90 day half-life, then +20 from the patch count incremement
        expect((UserCounter.last.decayed_count - 45).abs).to be <= 0.5
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
      json_response = JSON.parse(response_body)

      expect(json_response["data"]).to be_an(Array)
      expect(json_response["data"].length).to eq(2)

      # Check first counter
      first_counter = json_response["data"].find { |c| c["id"] == "tool_opens.kgp" }
      expect(first_counter["type"]).to eq("user-counter")
      expect(first_counter["attributes"]["count"]).to eq(50)
      expect(first_counter["attributes"]["decayed-count"]).to be_within(1.0).of(25.0)
      expect(first_counter["attributes"]["last-decay"]).to eq(today)

      # Check second counter
      second_counter = json_response["data"].find { |c| c["id"] == "other.kgp" }
      expect(second_counter["type"]).to eq("user-counter")
      expect(second_counter["attributes"]["count"]).to eq(60)
      expect(second_counter["attributes"]["decayed-count"]).to be_within(1.0).of(20.0)
      expect(second_counter["attributes"]["last-decay"]).to eq(today)
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
        expect((json_response["attributes"]["decayed-count"] - 45).abs).to be <= 0.5 # look within 0.5, close enough for timing differences
        expect(json_response["attributes"]["last-decay"]).to eq(Date.today.to_s)
        expect(UserCounter.last.count).to eq(70)
        # get close to 45 -- original value of 50 should decay to 25 with the 90 day half-life, then +20 from the patch count incremement
        expect((UserCounter.last.decayed_count - 45).abs).to be <= 0.5
        expect(UserCounter.last.last_decay).to eq(Date.today)
      end
    end
  end
end

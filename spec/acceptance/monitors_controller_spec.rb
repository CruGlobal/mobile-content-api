# frozen_string_literal: true

require "rails_helper"

describe MonitorsController, type: :request do
  context "#lb" do
    it "gives success because we have a valid database connection" do
      get "/monitors/lb"
      expect(response).to be_successful
    end
  end

  context "#commit" do
    it "renders git GIT_COMMIT env var" do
      ENV["GIT_COMMIT"] = "abc123"

      get "/monitors/commit"

      expect(response.body).to eq "abc123"
    end
  end
end

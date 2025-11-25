# frozen_string_literal: true

require "acceptance_helper"
require "sidekiq/testing"

resource "ContentStatus" do
  include ActiveJob::TestHelper

  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  get "content_status" do
    it "returns statistics JSON" do
      do_request

      expect(status).to be(200)
      json = JSON.parse(response_body)
      expect(json["tools"]["total"]).to eq(Resource.joins(:resource_type).where(resource_types: {name: "tract"}).count)
    end
  end
end

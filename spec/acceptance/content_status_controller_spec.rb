# frozen_string_literal: true

require "acceptance_helper"
require "sidekiq/testing"

resource "ContentStatus" do
  include ActiveJob::TestHelper

  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  get "content_status" do
    let(:country) { "us" }
    let!(:resource) { Resource.first }
    let!(:unfeatured_resource) { Resource.last }
    let!(:language_en) { Language.find_or_create_by!(code: "en", name: "English") }
    let!(:language_fr) { Language.find_or_create_by!(code: "fr", name: "French") }
    let!(:resource2) { Resource.joins(:resource_type).where("resource_types.name = ? AND resources.id NOT IN (?)", resource.resource_type.name, resource.id).first }
    let!(:resource3) { Resource.joins(:resource_type).where("resource_types.name = ? AND resources.id NOT IN (?)", resource.resource_type.name, [resource.id, resource2.id]).first }
    let!(:resource_score) do
      ResourceScore.create!(resource: resource, country: country, language: language_en, featured: true, featured_order: 1)
    end
    let!(:resource_score2) do
      ResourceScore.create!(resource: resource2, country: country, language: language_en, featured: false, featured_order: nil)
    end

    it "returns statistics JSON" do
      do_request

      expect(status).to be(200)
      json = JSON.parse(response_body)
      expect(json["tools"]["total"]).to eq(Resource.joins(:resource_type).where(resource_types: {name: "tract"}).count)
    end
  end
end

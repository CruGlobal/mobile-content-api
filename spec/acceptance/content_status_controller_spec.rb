# frozen_string_literal: true

require "acceptance_helper"
require "sidekiq/testing"

resource "ContentStatus" do
  include ActiveJob::TestHelper

  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  get "content_status" do
    let!(:resource_type_tract) { ResourceType.find_or_create_by!(name: "tract", dtd_file: "tract.xsd") }
    let!(:resource_type_lesson) { ResourceType.find_or_create_by!(name: "lesson", dtd_file: "lesson.xsd") }
    let!(:language_en) { Language.find_or_create_by!(code: "en", name: "English") }
    let!(:language_fr) { Language.find_or_create_by!(code: "fr", name: "French") }
    let!(:tract_resource) do
      Resource.create!(name: "Test Tract", resource_type: resource_type_tract, system: System.first,
        abbreviation: "test-tract")
    end
    let!(:lesson_resource) do
      Resource.create!(name: "Test Lesson", resource_type: resource_type_lesson, system: System.first,
        abbreviation: "test-lesson")
    end
    let!(:resource_score_tract) do
      ResourceScore.create!(
        resource: tract_resource,
        country: "us",
        language: language_en,
        featured: true,
        featured_order: 1,
        score: 5
      )
    end
    let!(:resource_score_lesson) do
      ResourceScore.create!(
        resource: lesson_resource,
        country: "us",
        language: language_en,
        featured: false,
        featured_order: nil,
        score: 3
      )
    end
    let!(:resource_default_order) do
      ResourceDefaultOrder.create!(
        resource: tract_resource,
        language: language_en,
        position: 1
      )
    end

    it "returns statistics JSON with metrics by resource type and country/language breakdown" do
      do_request

      expect(status).to be(200)
      json = JSON.parse(response_body)

      expect(json).to have_key("tools")
      expect(json).to have_key("lessons")
      expect(json).to have_key("countries")

      expect(json["tools"]).to include("default", "featured", "ranked", "total")
      expect(json["lessons"]).to include("default", "featured", "ranked", "total")

      expect(json["countries"]).to be_an(Array)
      expect(json["countries"][0]).to include("country_code", "languages")

      country_data = json["countries"].find { |c| c["country_code"] == "us" }
      expect(country_data).not_to be_nil

      language_data = country_data["languages"].find { |l| l["language_code"] == "en" }
      expect(language_data).to include(
        "language_code",
        "language_name",
        "lessons",
        "tools",
        "last_updated"
      )
    end
  end
end

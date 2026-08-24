# frozen_string_literal: true

require "acceptance_helper"

resource "ResourcesPersonalization" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  let(:resource_1) { Resource.find(1) }
  let(:resource_2) { Resource.find(2) }
  let(:resource_3) { Resource.find(3) }

  let!(:language_en) { Language.find_or_create_by!(code: "en", name: "English") }
  let!(:language_fr) { Language.find_or_create_by!(code: "fr", name: "French") }

  get "resources/featured" do
    let!(:resource_score) do
      ResourceScore.find_or_create_by!(resource: resource_1, country: "us",
        language: Language.find_or_create_by!(code: "en", name: "English")) do |rs|
        rs.featured = true
        rs.featured_order = 1
      end
    end

    context "with lang and country filters" do
      it "returns featured resources" do
        do_request filter: {lang: "en", country: "us"}, include: "resource-score"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(resource_score.id.to_s)
      end

      it "returns no featured resources for another language" do
        do_request filter: {lang: "fr", country: "us"}

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(0)
      end

      it "returns no featured resources for another country" do
        do_request filter: {lang: "en", country: "gb"}

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(0)
      end
    end

    context "with missing required filters" do
      it "returns bad request when both lang and country are missing" do
        do_request

        expect(status).to be(400)
        json = JSON.parse(response_body)
        expect(json["errors"].first["detail"]).to include("Language and Country Filters are required.")
      end

      it "returns bad request when country is missing" do
        do_request filter: {lang: "en"}

        expect(status).to be(400)
        json = JSON.parse(response_body)
        expect(json["errors"].first["detail"]).to include("Language and Country Filters are required.")
      end

      it "returns bad request when lang is missing" do
        do_request filter: {country: "us"}

        expect(status).to be(400)
        json = JSON.parse(response_body)
        expect(json["errors"].first["detail"]).to include("Language and Country Filters are required.")
      end
    end

    context "with invalid language code" do
      it "returns unprocessable content error" do
        do_request filter: {lang: "apple_orchard", country: "us"}

        expect(status).to be(422)
        json = JSON.parse(response_body)
        expect(json["errors"]).to be_present
        expect(json["errors"].first["detail"]).to include("Language not found")
      end
    end

    context "with resource_type filter" do
      let!(:tool_resource) { Resource.joins(:resource_type).where(resource_types: {name: "metatool"}).first }
      let!(:tool_score) do
        FactoryBot.create(:resource_score, resource: tool_resource, featured: true, featured_order: 2,
          language: language_en)
      end

      it "returns featured resources for specified resource type" do
        do_request({filter: {lang: "en", country: "us"}, resource_type: "metatool"})

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(tool_score.id.to_s)
      end

      context "inside filter param" do
        it "returns featured resources for specified resource type" do
          do_request filter: {lang: "en", country: "us", resource_type: "metatool"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(1)
          expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(tool_score.id.to_s)
        end
      end
    end
  end

  get "resources/ranked" do
    let(:resource_4) { Resource.find(4) }

    let!(:low_score) do
      ResourceScore.find_or_create_by!(resource: resource_1, country: "us", language: language_en) do |rs|
        rs.score = 5
      end
    end

    let!(:high_score) do
      ResourceScore.find_or_create_by!(resource: resource_2, country: "us", language: language_en) do |rs|
        rs.score = 10
      end
    end

    let!(:article_score) do
      ResourceScore.find_or_create_by!(resource: resource_3, country: "us", language: language_en) do |rs|
        rs.score = 3
      end
    end

    let!(:featured_without_score) do
      ResourceScore.find_or_create_by!(resource: resource_4, country: "us", language: language_en) do |rs|
        rs.featured = true
        rs.featured_order = 1
      end
    end

    context "with lang and country filters" do
      it "returns only resources with a score, ordered by score descending" do
        do_request filter: {lang: "en", country: "us"}

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].map { |d| d["id"] }).to eq(
          [resource_2.id.to_s, resource_1.id.to_s, resource_3.id.to_s]
        )
      end

      context "for another language" do
        let!(:french_score) do
          ResourceScore.find_or_create_by!(resource: resource_2, country: "us", language: language_fr) do |rs|
            rs.score = 4
          end
        end

        it "returns ranked resources for that language only" do
          do_request filter: {lang: "fr", country: "us"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].map { |d| d["id"] }).to eq([resource_2.id.to_s])
        end
      end

      context "for another country" do
        let!(:gb_score) do
          ResourceScore.find_or_create_by!(resource: resource_1, country: "gb", language: language_en) do |rs|
            rs.score = 9
          end
        end

        it "returns ranked resources for that country only" do
          do_request filter: {lang: "en", country: "GB"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].map { |d| d["id"] }).to eq([resource_1.id.to_s])
        end
      end
    end

    context "with missing required filters" do
      it "returns bad request when both lang and country are missing" do
        do_request

        expect(status).to be(400)
        json = JSON.parse(response_body)
        expect(json["errors"].first["detail"]).to include("Language and Country Filters are required.")
      end

      it "returns bad request when country is missing" do
        do_request filter: {lang: "en"}

        expect(status).to be(400)
        json = JSON.parse(response_body)
        expect(json["errors"].first["detail"]).to include("Language and Country Filters are required.")
      end

      it "returns bad request when lang is missing" do
        do_request filter: {country: "us"}

        expect(status).to be(400)
        json = JSON.parse(response_body)
        expect(json["errors"].first["detail"]).to include("Language and Country Filters are required.")
      end
    end

    context "with invalid language code" do
      it "returns unprocessable content error" do
        do_request filter: {lang: "apple_orchard", country: "us"}

        expect(status).to be(422)
        json = JSON.parse(response_body)
        expect(json["errors"]).to be_present
        expect(json["errors"].first["detail"]).to include("Language not found")
      end
    end

    context "with resource-type filter" do
      it "returns ranked resources for a single resource type" do
        do_request filter: {lang: "en", country: "us", "resource-type": "article"}

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].map { |d| d["id"] }).to eq([resource_3.id.to_s])
      end

      it "returns ranked resources for comma-separated resource types" do
        do_request filter: {lang: "en", country: "us", "resource-type": "tract,article"}

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].map { |d| d["id"] }).to eq(
          [resource_2.id.to_s, resource_1.id.to_s, resource_3.id.to_s]
        )
      end

      it "ignores resource-type outside the filter param" do
        do_request({filter: {lang: "en", country: "us"}, "resource-type": "article"})

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(3)
      end
    end
  end

  get "resources/default-order" do
    let!(:resource_default_order_1) do
      ResourceDefaultOrder.find_or_create_by!(resource: resource_1,
        language: Language.find_or_create_by!(code: "en", name: "English")) do |rdo|
        rdo.position = 1
      end
    end

    let!(:resource_default_order_2) do
      ResourceDefaultOrder.find_or_create_by!(resource: resource_2,
        language: Language.find_or_create_by!(code: "en", name: "English")) do |rdo|
        rdo.position = 2
      end
    end

    context "with missing required filters" do
      it "returns bad request when lang is missing" do
        do_request

        expect(status).to be(400)
        json = JSON.parse(response_body)
        expect(json["errors"].first["detail"]).to include("Language Filter is required.")
      end
    end

    context "with language filter" do
      it "returns default order resources for specified language" do
        do_request filter: {lang: "en"}

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(2)
        expect(json["data"][0]["id"]).to eq(resource_1.id.to_s)
      end

      it "returns empty array for non-existent language" do
        do_request filter: {lang: "de"}

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(0)
      end

      context "with case insensitive language code" do
        it "returns default order resources" do
          do_request filter: {lang: "EN"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(2)
        end
      end
    end

    context "with resource_type filter" do
      let!(:tool_resource) { Resource.joins(:resource_type).where(resource_types: {name: "metatool"}).first }
      let!(:tool_default_order) do
        ResourceDefaultOrder.find_or_create_by!(resource: tool_resource,
          language: Language.find_or_create_by!(code: "en", name: "English")) do |rdo|
          rdo.position = 3
        end
      end

      it "returns default order resources for specified resource type" do
        do_request({filter: {lang: "en"}, resource_type: "metatool"})

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["id"]).to eq(tool_resource.id.to_s)
      end

      context "inside filter param" do
        it "returns default order resources for specified resource type" do
          do_request filter: {lang: "en", resource_type: "metatool"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(1)
          expect(json["data"][0]["id"]).to eq(tool_resource.id.to_s)
        end
      end
    end

    context "with invalid language code" do
      it "returns unprocessable content error" do
        do_request filter: {lang: "invalid_lang_code_that_does_not_exist"}

        expect(status).to be(422)
        json = JSON.parse(response_body)
        expect(json["errors"]).to be_present
        expect(json["errors"].first["detail"]).to include("Language not found")
      end
    end

    context "returns resources in correct order" do
      let!(:resource_default_order_3) do
        ResourceDefaultOrder.find_or_create_by!(resource: resource_3,
          language: Language.find_or_create_by!(code: "en", name: "English")) do |rdo|
          rdo.position = 1
        end
      end

      it "orders by position ascending" do
        do_request filter: {lang: "en"}

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(3)
        expect(json["data"][0]["id"]).to eq(resource_3.id.to_s)
        expect(json["data"][1]["id"]).to eq(resource_1.id.to_s)
        expect(json["data"][2]["id"]).to eq(resource_2.id.to_s)
      end
    end
  end
end

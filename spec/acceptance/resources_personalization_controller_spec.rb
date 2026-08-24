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

    context "without filters" do
      it "returns featured resources" do
        do_request include: "resource-score"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(resource_score.id.to_s)
      end
    end

    context "with language filter" do
      it "returns featured resources for specified language" do
        do_request lang: "fr"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(0)
      end

      context "inside filter param" do
        it "returns featured resources for specified language" do
          do_request filter: {lang: "fr"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(0)
        end
      end
    end

    context "with invalid language code" do
      it "returns unprocessable content error" do
        do_request lang: "apple_orchard"

        expect(status).to be(422)
        json = JSON.parse(response_body)
        expect(json["errors"]).to be_present
        expect(json["errors"].first["detail"]).to include("Language not found")
      end
    end

    context "with country filter" do
      it "returns featured resources for specified country" do
        do_request country: "us"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(resource_score.id.to_s)
      end

      context "inside filter param" do
        it "returns featured resources for specified country" do
          do_request filter: {country: "us"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(1)
          expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(resource_score.id.to_s)
        end
      end
    end

    context "with resource_type filter" do
      let!(:tool_resource) { Resource.joins(:resource_type).where(resource_types: {name: "metatool"}).first }
      let!(:tool_score) do
        FactoryBot.create(:resource_score, resource: tool_resource, featured: true, featured_order: 2,
          language: Language.find_or_create_by!(code: "en", name: "English"))
      end

      it "returns featured resources for specified resource type" do
        do_request resource_type: "metatool"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(tool_score.id.to_s)
      end

      context "inside filter param" do
        it "returns featured resources for specified resource type" do
          do_request filter: {resource_type: "metatool"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(1)
          expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(tool_score.id.to_s)
        end
      end
    end
  end

  get "resources/default_order" do
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

    context "without filters" do
      it "returns default order resources" do
        do_request include: "language"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(2)
        expect(json["data"][0]["id"]).to eq(resource_1.id.to_s)
        expect(json["data"][1]["id"]).to eq(resource_2.id.to_s)
      end
    end

    context "with language filter" do
      it "returns default order resources for specified language" do
        do_request lang: "en"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(2)
        expect(json["data"][0]["id"]).to eq(resource_1.id.to_s)
      end

      it "returns empty array for non-existent language" do
        do_request lang: "de"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(0)
      end

      context "inside filter param" do
        it "returns default order resources for specified language" do
          do_request filter: {lang: "en"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(2)
          expect(json["data"][0]["id"]).to eq(resource_1.id.to_s)
        end
      end

      context "with case insensitive language code" do
        it "returns default order resources" do
          do_request lang: "EN"

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
        do_request resource_type: "metatool"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["id"]).to eq(tool_resource.id.to_s)
      end

      context "inside filter param" do
        it "returns default order resources for specified resource type" do
          do_request filter: {resource_type: "metatool"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(1)
          expect(json["data"][0]["id"]).to eq(tool_resource.id.to_s)
        end
      end
    end

    context "with language and resource_type filters" do
      let!(:tool_resource) { Resource.joins(:resource_type).where(resource_types: {name: "metatool"}).first }
      let!(:tool_default_order) do
        ResourceDefaultOrder.find_or_create_by!(resource: tool_resource,
          language: Language.find_or_create_by!(code: "en", name: "English")) do |rdo|
          rdo.position = 3
        end
      end

      it "returns default order resources matching both filters" do
        do_request lang: "en", resource_type: "metatool"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["id"]).to eq(tool_resource.id.to_s)
      end
    end

    context "with invalid language code" do
      it "returns unprocessable content error" do
        do_request lang: "invalid_lang_code_that_does_not_exist"

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
        do_request lang: "en"

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

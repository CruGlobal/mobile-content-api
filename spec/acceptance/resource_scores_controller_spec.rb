# frozen_string_literal: true

require "acceptance_helper"
require "sidekiq/testing"

resource "ResourceScores" do
  include ActiveJob::TestHelper

  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  let!(:resource) { Resource.first }
  let!(:unfeatured_resource) { Resource.last }
  let!(:language_en) { Language.find_or_create_by!(code: "en", name: "English") }
  let!(:language_fr) { Language.find_or_create_by!(code: "fr", name: "French") }

  get "resource_scores" do
    let!(:resource_score) do
      ResourceScore.find_or_create_by!(resource: resource, country: "us", language: language_en) do |rs|
        rs.featured = true
        rs.featured_order = 1
      end
    end

    context "without filters" do
      it "returns resource scores" do
        do_request include: "resource"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
      end
    end

    context "with language filter" do
      it "returns resource scores for specified language" do
        do_request lang: "fr"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(0)
      end

      context "inside filter param" do
        it "returns resource scores for specified language" do
          do_request filter: {lang: "fr"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(0)
        end
      end
    end

    context "with country filter" do
      it "returns resource scores for specified country" do
        do_request country: "us"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
      end

      context "inside filter param" do
        it "returns resource scores for specified country" do
          do_request filter: {country: "us"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(1)
          expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
        end
      end
    end

    context "with resource_type filter" do
      let!(:tool_resource_type) { ResourceType.find_by_name("metatool") }
      let!(:tool_resource) { Resource.joins(:resource_type).where(resource_types: {name: "metatool"}).first }
      let!(:tool_score) do
        FactoryBot.create(:resource_score, resource: tool_resource, featured: true, featured_order: 2,
          language: language_en)
      end

      it "returns resource scores for specified resource type" do
        do_request resource_type: "metatool"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(tool_resource.id.to_s)
      end

      context "inside filter param" do
        it "returns resource scores for specified resource type" do
          do_request filter: {resource_type: "metatool"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(1)
          expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(tool_resource.id.to_s)
        end
      end
    end
  end

  post "resource_scores" do
    requires_authorization

    let!(:resource_score) do
      ResourceScore.find_or_create_by!(resource: resource, country: "us", language: language_en) do |rs|
        rs.featured = true
        rs.featured_order = 1
      end
    end
    let(:valid_params) do
      {
        data: {
          type: "resource_score",
          attributes: {
            resource_id: resource.id,
            lang: language_en.code,
            country: "US",
            featured: true,
            featured_order: 1
          }
        }
      }
    end

    context "with valid parameters" do
      it "creates a new resource score" do
        do_request(valid_params)

        expect(status).to be(201)
        json = JSON.parse(response_body)
        expect(json["data"]["attributes"]["featured"]).to be true
        expect(json["data"]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
      end
    end

    context "with invalid parameters" do
      it "returns unprocessable entity" do
        do_request(data: {type: "resource_score", attributes: {featured: true, resource_id: resource.id}})

        expect(status).to be(422)
        json = JSON.parse(response_body)
        expect(json).to have_key("errors")
      end
    end
  end

  delete "resource_scores/:id" do
    requires_authorization

    let(:id) { resource_score.id }
    let!(:resource_score) do
      ResourceScore.find_or_create_by!(resource: resource, country: "us", language: language_en) do |rs|
        rs.featured = true
        rs.featured_order = 1
      end
    end

    it "deletes the resource score" do
      do_request

      expect(status).to be(200)
      expect(ResourceScore.exists?(id)).to be false
    end

    context "when an incorrect ID is sent" do
      let(:id) { "unknownId" }

      it "returns a not found error" do
        do_request

        expect(status).to be(404)
      end
    end
  end

  patch "resource_scores/:id" do
    requires_authorization

    let!(:resource_score) do
      ResourceScore.find_or_create_by!(resource: resource, country: "us", language: language_en) do |rs|
        rs.featured = true
        rs.featured_order = 1
      end
    end
    let(:id) { resource_score.id }
    let(:valid_update_params) do
      {
        data: {
          type: "resource_score",
          attributes: {
            featured_order: 2,
            country: "CA"
          }
        }
      }
    end

    context "with valid parameters" do
      it "updates the resource score" do
        do_request(valid_update_params)

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"]["attributes"]["featured-order"]).to eq(2)
        expect(json["data"]["attributes"]["country"]).to eq("CA".downcase)
        expect(json["data"]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
      end
    end

    context "with invalid parameters" do
      it "returns unprocessable entity" do
        do_request(data: {type: "resource_score", attributes: {featured_order: "invalid"}})

        expect(status).to be(422)
        json = JSON.parse(response_body)
        expect(json).to have_key("errors")
      end
    end

    context "when an incorrect ID is sent" do
      let(:id) { "unknownId" }

      it "returns a not found error" do
        do_request(valid_update_params)

        expect(status).to be(404)
      end
    end
  end

  patch "resource_scores/mass_update" do
    requires_authorization

    let(:country) { "US" }
    let(:lang) { "en" }
    let(:resource_ids) { [] }
    let(:resource_type) { ResourceType.find(resource.resource_type_id) }
    let(:featured) { true }
    let(:params) do
      {data: {attributes: {country: country, lang: lang, resource_ids: resource_ids,
                           resource_type: resource_type&.name}}}
    end

    context "with no country and lang params" do
      let(:country) { nil }
      let(:lang) { nil }

      context "when sending an empty array" do
        it "returns an error" do
          do_request(params)

          expect(status).to be(422)
        end
      end

      context "when sending 1 resource score" do
        let(:resource_ids) { [resource.id] }

        it "returns an error" do
          do_request(params)

          expect(status).to be(422)
        end
      end
    end

    context "with no country, lang, and resource_type params" do
      let(:country) { nil }
      let(:lang) { nil }
      let(:resource_type_attr) { nil }

      context "when sending an empty array" do
        it "returns an error" do
          do_request(params)

          expect(status).to be(422)
        end
      end

      context "when sending 1 resource score" do
        let(:resource_ids) { [resource.id] }

        it "returns an error" do
          do_request(params)

          expect(status).to be(422)
        end
      end
    end

    context "with no resource_type param" do
      let(:resource_type) { nil }

      context "when sending an empty array" do
        it "returns an error" do
          do_request(params)

          expect(status).to be(422)
          json = JSON.parse(response_body)
          expect(json["errors"][0]["detail"]).to include("Resource Type")
        end
      end

      context "when sending 1 resource score" do
        let(:resource_ids) { [resource.id] }

        it "returns an error" do
          do_request(params)

          expect(status).to be(422)
          json = JSON.parse(response_body)
          expect(json["errors"][0]["detail"]).to include("Resource Type")
        end
      end
    end

    context "with country and lang params" do
      context "with no previous resource score" do
        context "when sending an empty array" do
          it "returns an empty array" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(0)
          end
        end

        context "when sending 1 resource score" do
          let(:resource_ids) { [resource.id] }

          it "returns an array with 1 resource score" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(1)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
          end
        end

        context "when sending more than 1 resource score" do
          let!(:resource2) do
            Resource.joins(:resource_type).where("resource_types.name != ? AND resources.id NOT IN (?)",
              resource.resource_type.name, resource.id).first
          end
          let(:resource_ids) { [resource.id, resource2.id] }

          it "returns an array with more than 1 resource score" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
            expect(json["data"][1]["relationships"]["resource"]["data"]["id"]).to eq(resource2.id.to_s)
          end
        end
      end

      context "with previous resource scores" do
        let!(:resource2) do
          Resource.joins(:resource_type).where("resource_types.name = ? AND resources.id NOT IN (?)",
            resource.resource_type.name, resource.id).first
        end
        let!(:resource3) do
          Resource.joins(:resource_type).where("resource_types.name = ? AND resources.id NOT IN (?)",
            resource.resource_type.name, [resource.id, resource2.id]).first
        end
        let!(:resource_score) do
          ResourceScore.create!(resource: resource, country: country, language: language_en, featured: true,
            featured_order: 1)
        end
        let!(:resource_score2) do
          ResourceScore.create!(resource: resource2, country: country, language: language_en, featured: false,
            featured_order: nil)
        end

        context "when sending an empty array" do
          let(:resource_ids) { [] }

          it "deletes all matching resource scores" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(0)
          end

          context "when a resource has a score" do
            let(:resource_ids) { [] }

            before do
              resource_score.update!(score: 5)
            end

            it "removes featured status but keeps the score" do
              do_request(params)

              expect(status).to be(200)
              json = JSON.parse(response_body)
              expect(json["data"].count).to eq(1)
              expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)

              resource_score.reload
              expect(resource_score.featured).to be false
              expect(resource_score.featured_order).to be_nil
              expect(resource_score.score).to eq(5)
            end
          end
        end

        context "when sending 1 resource to replace" do
          let(:resource_ids) { [resource3.id, resource2.id] }

          it "returns an array with the replaced resource score" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource3.id.to_s)
            expect(json["data"][1]["relationships"]["resource"]["data"]["id"]).to eq(resource2.id.to_s)
          end
        end

        context "when sending more than 1 resource to replace" do
          let(:resource_ids) { [resource2.id, resource3.id, resource.id] }

          it "returns an array with the replaced resource scores" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(3)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource2.id.to_s)
            expect(json["data"][0]["attributes"]["featured"]).to eq(true)
            expect(json["data"][1]["relationships"]["resource"]["data"]["id"]).to eq(resource3.id.to_s)
            expect(json["data"][2]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
          end
        end

        context "when sending the same resource to replace" do
          let(:resource_ids) { [resource.id, resource2.id] }

          it "returns an array with the replaced resource score" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
            expect(json["data"][1]["relationships"]["resource"]["data"]["id"]).to eq(resource2.id.to_s)
          end
        end
      end
    end
  end

  patch "resource_scores/mass_update_ranked" do
    requires_authorization

    let(:country) { "US" }
    let(:lang) { "en" }
    let(:ranked_resources) { [] }
    let(:resource_type) { ResourceType.find(resource.resource_type_id) }
    let(:params) do
      {data: {attributes: {country: country, lang: lang, ranked_resources: ranked_resources,
                           resource_type: resource_type&.name}}}
    end

    context "with no country and lang params" do
      let(:country) { nil }
      let(:lang) { nil }

      context "when sending an empty array" do
        it "returns an error" do
          do_request(params)

          expect(status).to be(422)
        end
      end

      context "when sending 1 ranked resource" do
        let(:ranked_resources) { [{resource_id: resource.id, score: 10}] }

        it "returns an error" do
          do_request(params)

          expect(status).to be(422)
        end
      end
    end

    context "with no resource_type param" do
      let(:resource_type) { nil }

      context "when sending an empty array" do
        it "returns an error" do
          do_request(params)

          expect(status).to be(422)
          json = JSON.parse(response_body)
          expect(json["errors"][0]["detail"]).to include("Resource Type")
        end
      end

      context "when sending 1 ranked resource" do
        let(:ranked_resources) { [{resource_id: resource.id, score: 10}] }

        it "returns an error" do
          do_request(params)

          expect(status).to be(422)
          json = JSON.parse(response_body)
          expect(json["errors"][0]["detail"]).to include("Resource Type")
        end
      end
    end

    context "with country and lang params" do
      context "with no previous resource scores" do
        context "when sending an empty array" do
          it "returns an empty array" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(0)
          end
        end

        context "when sending 1 ranked resource" do
          let(:ranked_resources) { [{resource_id: resource.id, score: 10}] }

          it "returns an array with 1 resource score" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(1)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
            expect(json["data"][0]["attributes"]["score"]).to eq(10)
          end
        end

        context "when sending more than 1 ranked resource" do
          let!(:resource2) do
            Resource.joins(:resource_type).where("resource_types.name != ? AND resources.id NOT IN (?)",
              resource.resource_type.name, resource.id).first
          end
          let(:ranked_resources) { [{resource_id: resource.id, score: 20}, {resource_id: resource2.id, score: 10}] }

          it "returns an array with more than 1 resource score" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
            expect(json["data"][0]["attributes"]["score"]).to eq(20)
            expect(json["data"][1]["relationships"]["resource"]["data"]["id"]).to eq(resource2.id.to_s)
            expect(json["data"][1]["attributes"]["score"]).to eq(10)
          end

          it "returns resources sorted by score descending" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"][0]["attributes"]["score"]).to be >= json["data"][1]["attributes"]["score"]
          end
        end
      end

      context "with previous resource scores" do
        let!(:resource2) do
          Resource.joins(:resource_type).where("resource_types.name = ? AND resources.id NOT IN (?)",
            resource.resource_type.name, resource.id).first
        end
        let!(:resource3) do
          Resource.joins(:resource_type).where("resource_types.name = ? AND resources.id NOT IN (?)",
            resource.resource_type.name, [resource.id, resource2.id]).first
        end
        let!(:resource_score) do
          ResourceScore.create!(resource: resource, country: country, language: language_en, score: 15)
        end
        let!(:resource_score2) do
          ResourceScore.create!(resource: resource2, country: country, language: language_en, score: 5)
        end

        context "when sending an empty array" do
          let(:ranked_resources) { [] }

          it "clears all scores for matching resource scores" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)

            resource_score.reload
            resource_score2.reload
            expect(resource_score.score).to be_nil
            expect(resource_score2.score).to be_nil
          end
        end

        context "when sending 1 ranked resource to update" do
          let(:ranked_resources) { [{resource_id: resource.id, score: 20}] }

          it "returns an array with the updated resource score" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(1)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
            expect(json["data"][0]["attributes"]["score"]).to eq(20)
          end

          it "updates only the existing resource score" do
            do_request(params)

            resource_score.reload
            expect(resource_score.score).to eq(20)
          end
        end

        context "when sending more than 1 ranked resource to update" do
          let(:ranked_resources) { [{resource_id: resource.id, score: 18}, {resource_id: resource2.id, score: 12}] }

          it "returns an array with the updated resource scores" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]["attributes"]["score"]).to eq(18)
            expect(json["data"][1]["attributes"]["score"]).to eq(12)
          end

          it "returns resources sorted by score descending" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"][0]["attributes"]["score"]).to be >= json["data"][1]["attributes"]["score"]
          end
        end

        context "when sending a new resource to add" do
          let(:ranked_resources) { [{resource_id: resource3.id, score: 16}] }

          it "creates a new resource score" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(1)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource3.id.to_s)
            expect(json["data"][0]["attributes"]["score"]).to eq(16)
          end
        end

        context "when sending a mix of existing and new resources" do
          let(:ranked_resources) { [{resource_id: resource.id, score: 19}, {resource_id: resource3.id, score: 14}] }

          it "returns an array with updated and new resource scores" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]["attributes"]["score"]).to eq(19)
            expect(json["data"][1]["attributes"]["score"]).to eq(14)
          end

          it "returns resources sorted by score descending" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"][0]["attributes"]["score"]).to be >= json["data"][1]["attributes"]["score"]
          end
        end

        context "when resource_type filter is applied" do
          let(:ranked_resources) { [{resource_id: resource.id, score: 17}] }

          it "only updates resources of the specified type" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(1)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
          end
        end

        context "when updating with different scores" do
          let(:ranked_resources) do
            [
              {resource_id: resource.id, score: 20},
              {resource_id: resource2.id, score: 13},
              {resource_id: resource3.id, score: 7}
            ]
          end

          it "returns all resources sorted by score in descending order" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(3)
            expect(json["data"][0]["attributes"]["score"]).to eq(20)
            expect(json["data"][1]["attributes"]["score"]).to eq(13)
            expect(json["data"][2]["attributes"]["score"]).to eq(7)
          end
        end
      end
    end
  end
end

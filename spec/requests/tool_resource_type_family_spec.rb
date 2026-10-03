# frozen_string_literal: true

require "rails_helper"

# "tool" is the client-facing name for every tool format (tract + cyoa). The
# app shows both in one Tools list, so the dashboard must read and write their
# ordering as one slice. Each endpoint that takes a resource type is covered.
describe "Tool resource type family", type: :request do
  let(:admin) { FactoryBot.create(:user, admin: true) }
  let(:english) { Language.find_or_create_by!(code: "en") { |l| l.name = "English" } }

  let(:tract_type) { ResourceType.find_or_create_by!(name: "tract") { |t| t.dtd_file = "tract.xsd" } }
  let(:cyoa_type) { ResourceType.find_or_create_by!(name: "cyoa") { |t| t.dtd_file = "cyoa.xsd" } }
  let(:lesson_type) { ResourceType.find_or_create_by!(name: "lesson") { |t| t.dtd_file = "lesson.xsd" } }

  let!(:tract) { FactoryBot.create(:resource, name: "Four Laws", resource_type: tract_type) }
  let!(:cyoa) { FactoryBot.create(:resource, name: "Openers", resource_type: cyoa_type) }
  let!(:lesson) { FactoryBot.create(:resource, name: "A Lesson", resource_type: lesson_type) }

  def headers_for(user)
    {
      "Accept" => "application/vnd.api+json",
      "Content-Type" => "application/vnd.api+json",
      "Authorization" => AuthToken.encode({user_id: user.id})
    }
  end

  def ids_in(body)
    JSON.parse(body)["data"].map { |row| row["id"].to_i }
  end

  describe ResourceType do
    it "expands tool to both formats and passes other names through" do
      expect(ResourceType.expand_name("tool")).to eq(%w[tract cyoa])
      expect(ResourceType.expand_name("TOOL")).to eq(%w[tract cyoa])
      expect(ResourceType.expand_name("Lesson")).to eq(["lesson"])
    end

    it "resolves the ids an ordering write applies to" do
      expect(ResourceType.orderable_ids_for!("tool")).to contain_exactly(tract_type.id, cyoa_type.id)
      expect(ResourceType.orderable_ids_for!("tract")).to eq([tract_type.id])
      expect(ResourceType.orderable_ids_for!("cyoa")).to eq([cyoa_type.id])
      expect(ResourceType.orderable_ids_for!("lesson")).to eq([lesson_type.id])
    end

    it "keeps not-found and not-supported distinct" do
      ResourceType.find_or_create_by!(name: "article") { |t| t.dtd_file = "article.xsd" }

      expect { ResourceType.orderable_ids_for!("nonsense") }
        .to raise_error(InvalidRequestError, /not found/)
      expect { ResourceType.orderable_ids_for!("article") }
        .to raise_error(InvalidRequestError, /not supported/)
    end
  end

  describe "GET /resources?filter[resource_type]=" do
    # include/not_to include rather than exact lists: the test database is
    # seeded with other tracts.
    it "returns tracts and CYOA tools for tool, and only tracts for tract" do
      get "/resources?filter[resource_type]=tool"
      expect(ids_in(response.body)).to include(tract.id, cyoa.id)
      expect(ids_in(response.body)).not_to include(lesson.id)

      get "/resources?filter[resource_type]=tract"
      expect(ids_in(response.body)).to include(tract.id)
      expect(ids_in(response.body)).not_to include(cyoa.id)

      get "/resources?filter[resource_type]=lesson"
      expect(ids_in(response.body)).to include(lesson.id)
      expect(ids_in(response.body)).not_to include(tract.id, cyoa.id)
    end
  end

  describe "PATCH /resource_scores/mass_update (featured)" do
    let(:path) { "/resource_scores/mass_update" }

    def body(resource_type:, resource_ids:)
      {data: {attributes: {country: "us", lang: "en", resource_type: resource_type, resource_ids: resource_ids}}}.to_json
    end

    it "features tracts and CYOA tools in one ordered slice" do
      english
      patch path, params: body(resource_type: "tool", resource_ids: [cyoa.id, tract.id]), headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      featured = ResourceScore.where(country: "us", language: english, featured: true).order(:featured_order)
      expect(featured.map(&:resource_id)).to eq([cyoa.id, tract.id])

      get "/resources/featured?filter[country]=us&filter[lang]=en&filter[resource-type]=tool"
      expect(ids_in(response.body)).to eq([cyoa.id, tract.id])
    end

    it "unfeatures a CYOA tool left out of a later tool write, since it shares the slice" do
      english
      patch path, params: body(resource_type: "tool", resource_ids: [cyoa.id, tract.id]), headers: headers_for(admin)
      patch path, params: body(resource_type: "tool", resource_ids: [tract.id]), headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(ResourceScore.where(country: "us", language: english, featured: true).pluck(:resource_id)).to eq([tract.id])
    end

    it "still accepts tract alone, which leaves CYOA tools untouched" do
      english
      patch path, params: body(resource_type: "tool", resource_ids: [cyoa.id]), headers: headers_for(admin)
      patch path, params: body(resource_type: "tract", resource_ids: [tract.id]), headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(ResourceScore.where(country: "us", language: english, featured: true).pluck(:resource_id))
        .to contain_exactly(cyoa.id, tract.id)
    end

    it "rejects a lesson inside a tool write" do
      patch path, params: body(resource_type: "tool", resource_ids: [tract.id, lesson.id]), headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].first["detail"]).to include("Invalid IDs: #{lesson.id}")
    end

    it "rejects a CYOA tool inside a tract write" do
      patch path, params: body(resource_type: "tract", resource_ids: [cyoa.id]), headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "keeps rejecting unknown and unsupported types" do
      ResourceType.find_or_create_by!(name: "article") { |t| t.dtd_file = "article.xsd" }

      patch path, params: body(resource_type: "nonsense", resource_ids: []), headers: headers_for(admin)
      expect(JSON.parse(response.body)["errors"].first["detail"]).to include("not found")

      patch path, params: body(resource_type: "article", resource_ids: []), headers: headers_for(admin)
      expect(JSON.parse(response.body)["errors"].first["detail"]).to include("not supported")
    end
  end

  describe "PATCH /resource_scores/mass_update_ranked" do
    let(:path) { "/resource_scores/mass_update_ranked" }

    def body(resource_type:, ranked:)
      {data: {attributes: {country: "us", lang: "en", resource_type: resource_type, ranked_resources: ranked}}}.to_json
    end

    it "ranks tracts and CYOA tools together" do
      english
      patch path,
        params: body(resource_type: "tool", ranked: [{resource_id: cyoa.id, score: 9}, {resource_id: tract.id, score: 4}]),
        headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      # The response lists score rows, so read the order back from the table.
      ranked = ResourceScore.where(country: "us", language: english).where.not(score: nil).order(score: :desc)
      expect(ranked.map(&:resource_id)).to eq([cyoa.id, tract.id])

      get "/resource_scores?filter[country]=us&filter[lang]=en&filter[resource_type]=tool"
      expect(JSON.parse(response.body)["data"].size).to eq(2)
    end

    it "drops a CYOA score omitted from a later tool write" do
      english
      patch path, params: body(resource_type: "tool", ranked: [{resource_id: cyoa.id, score: 9}]), headers: headers_for(admin)
      patch path, params: body(resource_type: "tool", ranked: [{resource_id: tract.id, score: 5}]), headers: headers_for(admin)

      expect(ResourceScore.where(country: "us", language: english).where.not(score: nil).pluck(:resource_id)).to eq([tract.id])
    end
  end

  describe "PATCH /resource_default_orders/mass_update" do
    let(:path) { "/resource_default_orders/mass_update" }

    def body(resource_type:, resource_ids:)
      {data: {attributes: {lang: "en", resource_type: resource_type, resource_ids: resource_ids}}}.to_json
    end

    it "sets one default order across tracts and CYOA tools" do
      english
      patch path, params: body(resource_type: "tool", resource_ids: [cyoa.id, tract.id]), headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(ResourceDefaultOrder.where(language: english).order(:position).map(&:resource_id)).to eq([cyoa.id, tract.id])

      get "/resources/default-order?filter[lang]=en&filter[resource-type]=tool"
      expect(ids_in(response.body)).to eq([cyoa.id, tract.id])

      get "/resource_default_orders?filter[lang]=en&filter[resource_type]=tool"
      expect(ids_in(response.body)).to eq([cyoa.id, tract.id])
    end

    it "removes a CYOA default omitted from a later tool write" do
      english
      patch path, params: body(resource_type: "tool", resource_ids: [cyoa.id, tract.id]), headers: headers_for(admin)
      patch path, params: body(resource_type: "tool", resource_ids: [tract.id]), headers: headers_for(admin)

      expect(ResourceDefaultOrder.where(language: english).pluck(:resource_id)).to eq([tract.id])
    end
  end

  describe "GET /content_status" do
    it "counts CYOA tools as tools" do
      ResourceScore.create!(resource: cyoa, country: "us", language: english, featured: true, featured_order: 1, score: 3)

      get "/content_status", headers: {"Accept" => "application/vnd.api+json"}

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["tools"]["featured"]).to eq(1)
      expect(json["tools"]["ranked"]).to eq(1)
      us = json["countries"].find { |c| c["country_code"] == "us" }
      en = us["languages"].find { |l| l["language_code"] == "en" }
      expect(en["tools"]).to eq({"featured" => 1, "ranked" => 1})
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResourceScore, type: :model do
  let(:resource) { Resource.first }
  subject(:resource_score) { FactoryBot.build(:resource_score, resource: resource) }

  describe "validations" do
    let(:resource_score_with_resource) do
      FactoryBot.create(
        :resource_score, resource: resource, featured: true, featured_order: 1, country: "US", lang: "en"
      )
    end
    it { is_expected.to be_valid }

    context "uniqueness validation" do
      let!(:previous_resource_score) do
        FactoryBot.create(:resource_score, resource: resource, country: "us", lang: "en")
      end

      it "validates uniqueness of resource_id scoped to country, lang and resource_type" do
        duplicate = FactoryBot.build(:resource_score, resource: resource, country: "us", lang: "en")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:resource_id]).to include("should have only one score per country, language and resource type")
      end
    end

    context "featured validation" do
      it "requires featured_order when featured is true" do
        resource_score.featured = true
        resource_score.featured_order = nil
        expect(resource_score).not_to be_valid
        expect(resource_score.errors[:featured_order]).to include("must be present if resource is featured")
      end

      context "having a resource score created previously" do
        let!(:previous_resource_score) do
          ResourceScore.create(resource: resource, featured: true, featured_order: 1, country: "us", lang: "en")
        end

        it "validates uniqueness of featured_order within country and language" do
          duplicate = ResourceScore.new(resource: resource, featured: true, featured_order: 1, country: "us",
            lang: "en")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:featured_order]).to include("is already taken for this country and language")
        end

        it "allows same featured_order for different country" do
          resource2 = Resource.last
          different_country = FactoryBot.build(:resource_score, resource: resource2, featured: true, featured_order: 1,
            country: "CA", lang: "en")
          expect(different_country).to be_valid
        end

        it "allows same featured_order for different language" do
          resource2 = Resource.last
          different_lang = FactoryBot.build(:resource_score, resource: resource2, featured: true, featured_order: 1,
            country: "US", lang: "es")
          expect(different_lang).to be_valid
        end
      end

      it "allows same featured_order for different resources" do
        resource_score_with_resource
        different_resource = FactoryBot.build(:resource_score, resource: Resource.last, featured: true,
          featured_order: 1, country: "US", lang: "en")
        expect(different_resource).to be_valid
      end
    end
  end

  describe "callbacks" do
    context "before_save" do
      it "downcases country" do
        resource_score.country = "US"
        resource_score.save
        expect(resource_score.country).to eq("us")
      end

      it "downcases lang" do
        resource_score.lang = "EN"
        resource_score.save
        expect(resource_score.lang).to eq("en")
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResourceScore, type: :model do
  let(:resource) { FactoryBot.create(:resource) }
  subject(:resource_score) { FactoryBot.build(:resource_score, resource: resource) }

  describe "associations" do
    it { is_expected.to belong_to(:resource) }
  end

  describe "validations" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:country) }
    it { is_expected.to validate_presence_of(:lang) }

    context "score validation" do
      it { is_expected.to validate_numericality_of(:score).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(20).allow_nil }
    end

    context "featured_order validation" do
      it { is_expected.to validate_numericality_of(:featured_order).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(10).allow_nil }
    end

    context "default_order validation" do
      it { is_expected.to validate_numericality_of(:default_order).only_integer.is_greater_than_or_equal_to(1).allow_nil }
    end

    context "uniqueness validation" do
      before { FactoryBot.create(:resource_score, resource: resource, country: "US", lang: "en") }

      it "validates uniqueness of resource_id scoped to country and lang" do
        duplicate = FactoryBot.build(:resource_score, resource: resource, country: "US", lang: "en")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:resource_id]).to include("should have only one score per country and language")
      end
    end

    context "featured validation" do
      it "requires featured_order when featured is true" do
        resource_score.featured = true
        resource_score.featured_order = nil
        expect(resource_score).not_to be_valid
        expect(resource_score.errors[:featured_order]).to include("must be present if resource is featured")
      end

      it "validates uniqueness of featured_order within country and language" do
        FactoryBot.create(:resource_score, featured: true, featured_order: 1, country: "US", lang: "en")
        duplicate = FactoryBot.build(:resource_score, featured: true, featured_order: 1, country: "US", lang: "en")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:featured_order]).to include("is already taken for this country and language")
      end

      it "allows same featured_order for different country" do
        FactoryBot.create(:resource_score, featured: true, featured_order: 1, country: "US", lang: "en")
        different_country = FactoryBot.build(:resource_score, featured: true, featured_order: 1, country: "CA", lang: "en")
        expect(different_country).to be_valid
      end

      it "allows same featured_order for different language" do
        FactoryBot.create(:resource_score, featured: true, featured_order: 1, country: "US", lang: "en")
        different_lang = FactoryBot.build(:resource_score, featured: true, featured_order: 1, country: "US", lang: "es")
        expect(different_lang).to be_valid
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

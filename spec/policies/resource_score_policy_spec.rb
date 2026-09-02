# frozen_string_literal: true

require "rails_helper"

describe ResourceScorePolicy do
  subject(:policy) { described_class.new(user, score) }

  let(:english) { Language.find_or_create_by!(code: "en") { |l| l.name = "English" } }
  let(:spanish) { Language.find_or_create_by!(code: "es") { |l| l.name = "Spanish" } }
  # Reuse the seeded resource type: ResourceType validates name uniqueness, so
  # letting the factory build its own "tract" collides with db/seeds.rb.
  let(:tract) { ResourceType.find_by(name: "tract") || FactoryBot.create(:tract_resource_type) }
  let(:resource) { FactoryBot.create(:resource, resource_type: tract) }

  def build_score(country:, language:)
    ResourceScore.new(resource: resource, country: country, language: language)
  end

  def grant(user, country:, language:)
    FactoryBot.create(:resource_score_permission, user: user, country: country, language: language)
  end

  describe "no user" do
    let(:user) { nil }
    let(:score) { build_score(country: "us", language: english) }

    it "denies create" do
      expect(policy.create?).to be false
    end

    it "denies destroy" do
      expect(policy.destroy?).to be false
    end
  end

  describe "admin" do
    let(:user) { FactoryBot.create(:user, admin: true) }
    let(:score) { build_score(country: "vn", language: spanish) }

    it "is a superuser bypass, with no grants at all" do
      expect(user.resource_score_permissions).to be_empty
      expect(policy.create?).to be true
      expect(policy.destroy?).to be true
      expect(policy.mass_update?).to be true
      expect(policy.mass_update_ranked?).to be true
    end
  end

  describe "non-admin with no grants" do
    let(:user) { FactoryBot.create(:user, admin: false) }
    let(:score) { build_score(country: "us", language: english) }

    it "denies everything" do
      expect(policy.create?).to be false
      expect(policy.destroy?).to be false
      expect(policy.mass_update?).to be false
    end
  end

  describe "non-admin granted us/en" do
    let(:user) { FactoryBot.create(:user, admin: false) }

    before { grant(user, country: "us", language: english) }

    it "allows the granted pair" do
      policy = described_class.new(user, build_score(country: "us", language: english))
      expect(policy.create?).to be true
    end

    it "denies another language in the same country" do
      policy = described_class.new(user, build_score(country: "us", language: spanish))
      expect(policy.create?).to be false
    end

    it "denies the same language in another country" do
      policy = described_class.new(user, build_score(country: "mx", language: english))
      expect(policy.create?).to be false
    end

    it "normalizes an uppercase incoming country" do
      policy = described_class.new(user, build_score(country: "US", language: english))
      expect(policy.create?).to be true
    end

    it "denies a blank country" do
      policy = described_class.new(user, build_score(country: nil, language: english))
      expect(policy.create?).to be false
    end
  end

  describe "wildcard grant (every language in a country)" do
    let(:user) { FactoryBot.create(:user, admin: false) }

    before { grant(user, country: "mx", language: nil) }

    it "allows any language in that country" do
      expect(described_class.new(user, build_score(country: "mx", language: english)).create?).to be true
      expect(described_class.new(user, build_score(country: "mx", language: spanish)).create?).to be true
    end

    it "does not leak into other countries" do
      expect(described_class.new(user, build_score(country: "us", language: english)).create?).to be false
    end
  end

  describe "grants do not form a cartesian product" do
    let(:user) { FactoryBot.create(:user, admin: false) }

    before do
      grant(user, country: "us", language: english)
      grant(user, country: "mx", language: spanish)
    end

    it "allows only the two granted pairs" do
      expect(described_class.new(user, build_score(country: "us", language: english)).create?).to be true
      expect(described_class.new(user, build_score(country: "mx", language: spanish)).create?).to be true
    end

    it "denies the crossed pairs" do
      expect(described_class.new(user, build_score(country: "us", language: spanish)).create?).to be false
      expect(described_class.new(user, build_score(country: "mx", language: english)).create?).to be false
    end
  end

  describe "#update?" do
    let(:user) { FactoryBot.create(:user, admin: false) }
    let!(:persisted) do
      ResourceScore.create!(resource: resource, country: "us", language: english, score: 5)
    end

    before { grant(user, country: "us", language: english) }

    it "allows an in-place edit" do
      persisted.assign_attributes(score: 7)
      expect(described_class.new(user, persisted).update?).to be true
    end

    it "denies moving a score out of the granted pair" do
      persisted.assign_attributes(country: "mx")
      expect(described_class.new(user, persisted).update?).to be false
    end

    it "denies moving a score out via the language" do
      persisted.assign_attributes(language: spanish)
      expect(described_class.new(user, persisted).update?).to be false
    end

    context "when the user is granted the target but not the source" do
      let!(:foreign) do
        ResourceScore.create!(resource: resource, country: "mx", language: spanish, score: 5)
      end

      it "denies capturing it into the granted pair" do
        foreign.assign_attributes(country: "us", language: english)
        expect(described_class.new(user, foreign).update?).to be false
      end
    end
  end
end

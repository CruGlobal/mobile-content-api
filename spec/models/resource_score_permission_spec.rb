# frozen_string_literal: true

require "rails_helper"

describe ResourceScorePermission do
  let(:user) { FactoryBot.create(:user) }
  let(:english) { Language.find_or_create_by!(code: "en") { |l| l.name = "English" } }

  it "downcases the country before validating" do
    permission = described_class.create!(user: user, country: "US", language: english)

    expect(permission.country).to eq("us")
  end

  it "rejects a country that is not ISO 3166-1 alpha-2" do
    permission = described_class.new(user: user, country: "uk", language: english)

    expect(permission).not_to be_valid
    expect(permission.errors[:country].first).to match(/not a recognized ISO 3166-1/)
  end

  it "accepts gb, the real code for the United Kingdom" do
    expect(described_class.new(user: user, country: "gb", language: english)).to be_valid
  end

  it "requires a country" do
    expect(described_class.new(user: user, country: nil, language: english)).not_to be_valid
  end

  it "allows a nil language as the country-wide wildcard" do
    expect(described_class.new(user: user, country: "mx", language: nil)).to be_valid
  end

  it "rejects a duplicate pair for the same user" do
    described_class.create!(user: user, country: "us", language: english)
    duplicate = described_class.new(user: user, country: "us", language: english)

    expect(duplicate).not_to be_valid
  end

  it "rejects a duplicate wildcard for the same user" do
    described_class.create!(user: user, country: "us", language: nil)
    duplicate = described_class.new(user: user, country: "us", language: nil)

    expect(duplicate).not_to be_valid
  end

  it "allows the same pair for a different user" do
    described_class.create!(user: user, country: "us", language: english)
    other = described_class.new(user: FactoryBot.create(:user), country: "us", language: english)

    expect(other).to be_valid
  end

  describe "#covers?" do
    it "matches its own pair, case-insensitively" do
      permission = described_class.new(country: "us", language: english)

      expect(permission.covers?("us", english.id)).to be true
      expect(permission.covers?("US", english.id)).to be true
    end

    it "does not match another language" do
      permission = described_class.new(country: "us", language: english)

      expect(permission.covers?("us", english.id + 1)).to be false
    end

    it "matches every language when it is a wildcard" do
      permission = described_class.new(country: "mx", language: nil)

      expect(permission.covers?("mx", english.id)).to be true
      expect(permission.covers?("mx", nil)).to be true
    end

    it "never matches a blank country" do
      expect(described_class.new(country: "us", language: english).covers?(nil, english.id)).to be false
    end
  end

  describe "User#resource_score_grants" do
    it "nests grants by country and renders the wildcard as *" do
      spanish = Language.find_or_create_by!(code: "es") { |l| l.name = "Spanish" }
      described_class.create!(user: user, country: "us", language: english)
      described_class.create!(user: user, country: "us", language: spanish)
      described_class.create!(user: user, country: "mx", language: nil)

      grants = user.resource_score_grants

      expect(grants["us"]).to match_array(%w[en es])
      expect(grants["mx"]).to eq(["*"])
    end
  end
end

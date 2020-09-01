require "rails_helper"

describe GlobalActivityAnalytics do
  describe ".instance" do
    subject { described_class.instance }

    it "returns instance with intial values" do
      expect(subject.id).to eq(1)
      expect(subject.users).to eq(0)
      expect(subject.countries).to eq(0)
      expect(subject.launches).to eq(0)
      expect(subject.gospel_presentations).to eq(0)
      expect(subject.actual?).to eq(false)
    end

    it "returns singleton" do
      expect(described_class.instance.id).to eq(1)
      expect { described_class.instance }.not_to change(described_class, :count)
      expect(described_class.instance.id).to eq(1)
    end
  end

  describe ".create" do
    it "does not allow to create multiple instances" do
      described_class.instance
      expect { described_class.create! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe ToolGroup, type: :model do
  context "create new tool-group" do
    subject { ToolGroup.new(name: "Group 1", suggestions_weight: 1.0) }

    it "is valid with a unique name" do
      expect(subject).to be_valid
    end

    it "is not valid with a duplicate name" do
      FactoryBot.create(:tool_group)
      attributes = {name: "Group 1", suggestions_weight: 1.0}
      expect { described_class.create!(attributes) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("has already been taken")
    end

    it "validates creation with valid attributes" do
      attributes = {name: "test", suggestions_weight: 1.0}

      expect do
        result = described_class.create!(attributes)
        expect(result.name).to eq("test")
        expect(result.suggestions_weight).to eq(1.0)
      end.to change(ToolGroup, :count).by(1)
    end

    it "raises an error if the 'name' attribute does not exist" do
      attributes = {name: nil, suggestions_weight: 1.0}
      expect { described_class.create!(attributes) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "raises an error if the 'suggestions_weight' attribute does not exist" do
      attributes = {name: "test", suggestions_weight: nil}
      expect { described_class.create!(attributes) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end

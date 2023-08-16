require "rails_helper"

RSpec.describe ToolFilterService do
  let(:languages) { ["es", "en"] }
  let(:countries) { ["US", "ES"] }
  let(:country_it) { ["IT"] }
  let(:openness) { [1, 2] }
  let(:confidence) { [1, 2] }

  let(:resource_1) { Resource.find(1) }
  let(:resource_2) { Resource.find(2) }
  let(:resource_3) { Resource.find(3) }
  let(:tool_group_one) { FactoryBot.create(:tool_group, name: "one") }
  let(:tool_group_two) { FactoryBot.create(:tool_group, name: "two") }
  let(:tool_group_three) { FactoryBot.create(:tool_group, name: "three") }

  before(:each) do
    # tool_group_one
    FactoryBot.create(:rule_language, tool_group: tool_group_one, languages: languages)
    FactoryBot.create(:rule_country, tool_group: tool_group_one, countries: countries)
    FactoryBot.create(:rule_praxis, tool_group: tool_group_one, openness: openness, confidence: confidence)

    ResourceToolGroup.create!(resource_id: resource_2.id, tool_group_id: tool_group_one.id, suggestions_weight: 1.3)
    ResourceToolGroup.create!(resource_id: resource_3.id, tool_group_id: tool_group_one.id, suggestions_weight: 1.0)
    ResourceToolGroup.create!(resource_id: resource_1.id, tool_group_id: tool_group_one.id, suggestions_weight: 2.0)

    # tool_group_two
    FactoryBot.create(:rule_country, tool_group: tool_group_two, countries: country_it)

    ResourceToolGroup.create!(resource_id: resource_1.id, tool_group_id: tool_group_two.id, suggestions_weight: 2.0)
  end

  context "when tool group without rules" do
    before do
      # tool_group_three
      ResourceToolGroup.create!(resource_id: resource_1.id, tool_group_id: tool_group_three.id, suggestions_weight: 2.0)
    end

    it "it returns resources" do
      params = {}

      expect(ToolFilterService.new(params).call.count).to eq 1
      expect(ToolFilterService.new(params).call.empty?).to eq false
    end
  end

  context "when matches all params" do
    it "it returns resources" do
      params = {"filter" => {"country" => "es", "language" => ["es"], "openness" => "1", "confidence" => "2"}}

      expect(ToolFilterService.new(params).call.count).to eq 3
      expect(ToolFilterService.new(params).call.empty?).to eq false
    end
  end

  context "when matches unique country rule" do
    it "it returns resources" do
      params = {"filter" => {"country" => "it"}}

      expect(ToolFilterService.new(params).call.count).to eq 1
      expect(ToolFilterService.new(params).call.empty?).to eq false
    end
  end

  context "when for country rule" do
    it "it returns no resources if country does not matches" do
      params = {"filter" => {"country" => "nl", "language" => ["fr"], "openness" => "1", "confidence" => "2"}}

      expect(ToolFilterService.new(params).call.empty?).to eq true
    end
  end

  context "when for languages rule" do
    it "it returns no resources if language does not matches" do
      params = {"filter" => {"country" => "fr", "language" => ["de"], "openness" => "1", "confidence" => "2"}}

      expect(ToolFilterService.new(params).call.empty?).to eq true
    end
  end

  context "when for praxes rule" do
    context "when negative rule false" do
      context "for confidence present" do
        it "it returns no resources if confidence does not matches" do
          params = {"filter" => {"country" => "fr", "language" => ["fr"], "openness" => "1", "confidence" => "5"}}

          expect(ToolFilterService.new(params).call.empty?).to eq true
        end
      end

      context "for openness present" do
        it "it returns no resources if openness does not matches" do
          params = {"filter" => {"country" => "fr", "language" => ["fr"], "openness" => "5", "confidence" => "2"}}

          expect(ToolFilterService.new(params).call.empty?).to eq true
        end
      end
    end

    context "when negative rule true" do
      before do
        RulePraxis.first.update!(negative_rule: true)
      end

      context "for confidence present" do
        it "it returns no resources if confidence matches" do
          params = {"filter" => {"country" => "fr", "language" => ["fr"], "openness" => "5", "confidence" => "2"}}

          expect(ToolFilterService.new(params).call.empty?).to eq true
        end
      end

      context "for openness present" do
        it "it returns no resources if openness matches" do
          params = {"filter" => {"country" => "us", "language" => ["en"], "openness" => "1", "confidence" => "5"}}

          expect(ToolFilterService.new(params).call.empty?).to eq true
        end
      end
    end
  end
end

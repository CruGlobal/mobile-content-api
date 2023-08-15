# spec/serializers/post_serializer_spec.rb
require "rails_helper"

RSpec.describe ToolGroupSerializer, type: :serializer do
  let(:tool_group) { FactoryBot.create(:tool_group) } # Use FactoryBot or any other fixture mechanism
  let(:languages) { ["es", "en"] }
  let(:countries) { ["US", "ES"] }
  let(:openness) { [1, 2] }
  let(:confidence) { [1, 2] }
  let(:current_datetime) { DateTime.now }

  subject { described_class.new(tool_group) }

  before do
    FactoryBot.create(:rule_language, tool_group: tool_group, languages: languages, created_at: current_datetime, updated_at: current_datetime)
    FactoryBot.create(:rule_country, tool_group: tool_group, countries: countries)
    FactoryBot.create(:rule_praxis, tool_group: tool_group, openness: openness, confidence: confidence)
  end

  it "serializes custom_rule_languages" do
    custom_rule_languages = subject.custom_rule_languages.as_json
    rule_language = RuleLanguage.first

    expect(custom_rule_languages.first).to include(
      "id" => RuleLanguage.first.id,
      "tool_group_id" => tool_group.id,
      "languages" => languages,
      "negative_rule" => false,
      "created_at" => rule_language.created_at.as_json,
      "updated_at" => rule_language.updated_at.as_json
    )
  end

  it "serializes custom_rule_countries" do
    custom_rule_countries = subject.custom_rule_countries.as_json
    rule_country = RuleCountry.first

    expect(custom_rule_countries.first).to include(
      "id" => rule_country.id,
      "tool_group_id" => tool_group.id,
      "countries" => countries,
      "negative_rule" => false,
      "created_at" => rule_country.created_at.as_json,
      "updated_at" => rule_country.updated_at.as_json
    )
  end

  it "serializes custom_rule_praxis" do
    custom_rule_praxes = subject.custom_rule_praxis.as_json
    rule_praxis = RulePraxis.first

    expect(custom_rule_praxes.first).to include(
      "id" => rule_praxis.id,
      "tool_group_id" => tool_group.id,
      "openness" => openness,
      "confidence" => confidence,
      "negative_rule" => false,
      "created_at" => rule_praxis.created_at.as_json,
      "updated_at" => rule_praxis.updated_at.as_json
    )
  end
end

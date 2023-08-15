# spec/serializers/post_serializer_spec.rb
require 'rails_helper'

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

  it 'serializes the custom_rule_languages' do
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
end

FactoryBot.define do
  factory :tool_group_rule_language do
    tool_group_id { 1 }
    negative_rule { true } 
    languages { ["en"] }
  end
end

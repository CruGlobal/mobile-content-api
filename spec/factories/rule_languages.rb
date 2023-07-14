FactoryBot.define do
  factory :rule_language do
    tool_group_id { 1 }
    negative_rule { true } 
    languages { ["en"] }
  end
end

FactoryBot.define do
  factory :rule_praxi do
    tool_group_id { 1 }
    negative_rule { true } 
    openness { [1, 2, 3] }
    confidence { [4, 5, 6] }
  end
end

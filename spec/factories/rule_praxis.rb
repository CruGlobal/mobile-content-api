FactoryBot.define do
  factory :rule_praxis do
    tool_group_id { 1 }
    negative_rule { false }
    openness { [1, 2, 3] }
    confidence { [4, 5] }
  end
end

FactoryBot.define do
  factory :rule_country do
    tool_group_id { 1 }
    negative_rule { true } 
    countries { ["BR"] }
  end
end

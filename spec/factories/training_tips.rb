FactoryBot.define do
  factory :training_tip do
    tool { "Tool 1" }
    locale { "en" }
    tip_id { 1 }
    is_completed { true }
  end
end

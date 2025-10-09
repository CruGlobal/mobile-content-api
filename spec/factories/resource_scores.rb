FactoryBot.define do
  factory :resource_score do
    resource_id { 1 }
    featured { false }
    country { "USA" }
    lang { "en" }
    score { 1 }
    user_score_average { 1.5 }
    user_score_count { 1 }
  end
end

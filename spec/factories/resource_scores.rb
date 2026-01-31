# frozen_string_literal: true

FactoryBot.define do
  factory :resource_score do
    resource
    language { association :language, code: "en" }
    featured { true }
    featured_order { 1 }
    country { "us" }
    score { 1 }
    user_score_average { 1.5 }
    user_score_count { 1 }
  end
end

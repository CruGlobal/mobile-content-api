# frozen_string_literal: true

FactoryBot.define do
  factory :resource_score do
    resource
    featured { false }
    featured_order { 1 }
    country { "us" }
    lang { "en" }
    score { 1 }
    default_order { 1 }
    user_score_average { 1.5 }
    user_score_count { 1 }
  end
end

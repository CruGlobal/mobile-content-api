# frozen_string_literal: true

FactoryBot.define do
  factory :resource_score_permission do
    user
    country { "us" }
    language { association :language, code: "en" }

    # "every language in this country"
    trait :all_languages do
      language { nil }
    end
  end
end

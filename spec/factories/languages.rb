# frozen_string_literal: true

FactoryBot.define do
  factory :language do
    name { "English" }
    code { "en" }
    direction { "ltr" }
    force_language_name { false }
  end
end

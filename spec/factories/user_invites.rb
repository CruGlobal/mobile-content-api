# frozen_string_literal: true

FactoryBot.define do
  factory :user_invite do
    sequence(:email) { |n| "invitee#{n}@partner.org" }
    first_name { "Jane" }
    last_name { "Smith" }
    admin { false }
    # The wildcard needs no Language row, so the default invite is standalone.
    grants { {"us" => ["*"]} }
    invited_by factory: :user, admin: true

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :accepted do
      accepted_at { 1.hour.ago }
      accepted_by factory: :user
    end

    trait :superadmin do
      admin { true }
      grants { {} }
    end
  end
end

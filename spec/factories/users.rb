FactoryBot.define do
  factory :user do
    first_name { "Wonder" }
    last_name { "Woman" }
    sequence :email do |n|
      "diana#{n}@themyscira.pi"
    end
    sso_guid { SecureRandom.uuid }
  end
end

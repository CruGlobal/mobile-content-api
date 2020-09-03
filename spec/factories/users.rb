FactoryBot.define do
  factory :user do
    first_name { "Wonder" }
    last_name { "Woman" }
    email { "diana@themyscira.pi" }
    sso_guid { SecureRandom.uuid }
  end
end

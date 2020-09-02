FactoryBot.define do
  factory :user do
    first_name { "Wonder" }
    last_name { "Woman" }
    email { "diana@themyscira.pi" }
    okta_id { "1" }
  end
end

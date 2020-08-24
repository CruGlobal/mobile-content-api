FactoryBot.define do
  factory :auth_token do
    sequence(:token) do |n|
      "token_#{n}"
    end
    expiration { 1.week.from_now }
    association :access_code
  end
end

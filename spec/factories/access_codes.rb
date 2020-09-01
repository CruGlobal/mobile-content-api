FactoryBot.define do
  factory :access_code do
    sequence(:code) do |n|
      "token_#{n}"
    end
    expiration { 1.week.from_now }
  end
end

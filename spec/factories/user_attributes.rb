FactoryBot.define do
  factory :user_attribute do
    user_id { 1 }
    key { "remove_attribute" }
    value { "some-value" }
  end
end

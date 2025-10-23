FactoryBot.define do
  factory :resource_default_order do
    resource
    sequence(:position) { |n| n }
    lang { "en" }
  end
end

FactoryBot.define do
  factory :resource_default_order do
    resource
    language { Language.find_by(code: "en") || FactoryBot.create(:language, code: "en") }
    sequence(:position) { |n| n }
  end
end

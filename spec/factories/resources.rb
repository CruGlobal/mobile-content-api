FactoryBot.define do
  factory :resource do
    sequence :name do |n|
      "name_#{n}"
    end

    sequence :abbreviation do |n|
      "abbrv_#{n}"
    end

    system do
      System.first || create(:system)
    end

    association :resource_type, factory: :tract_resource_type
  end
end

FactoryBot.define do
  factory :tip do
    sequence :name do |n|
      "name_#{n}"
    end
  end
end

FactoryBot.define do
  factory :page do
    sequence :filename do |n|
      "filename_#{n}"
    end
    sequence :position
  end
end

FactoryBot.define do
  factory :custom_tip do
    structure { "MyString" }
    tip_id { 1 }
    language_id { 1 }
  end
end

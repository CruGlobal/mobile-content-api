FactoryBot.define do
  factory :user_counter do
    user_id { 1 }
    counter_name { "MyString" }
    count { 1 }
    decayed_count { 1.5 }
    last_decay { "2021-11-10" }
  end
end

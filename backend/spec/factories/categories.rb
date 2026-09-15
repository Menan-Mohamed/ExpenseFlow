FactoryBot.define do
  factory :category do
    name { "MyString" }
    auto_approve_limit { "9.99" }
    active { false }
  end
end

FactoryBot.define do
  factory :expense do
    user { nil }
    category { nil }
    title { "MyString" }
    description { "MyText" }
    amount { "9.99" }
    spent_date { "2026-09-15" }
    state { 1 }
    payment_reference { "MyString" }
  end
end

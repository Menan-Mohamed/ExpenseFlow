FactoryBot.define do
  factory :expense do
    association :user
    association :category
    title { "Office supplies" }
    description { "Printer paper" }
    amount { 25.50 }
    spent_date { Date.current }
    state { :draft }
    payment_reference { "REF-123" }
  end
end

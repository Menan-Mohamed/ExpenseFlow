FactoryBot.define do
  factory :category do
    sequence(:name) { |number| "Category #{number}" }
    auto_approve_limit { 1000 }
    active { true }
  end
end

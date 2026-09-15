FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    auto_approve_limit { 50 }
    active { true }
  end
end
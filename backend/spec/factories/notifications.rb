FactoryBot.define do
  factory :notification do
    association :user
    content { "Expense submitted" }
    is_read { false }
  end
end

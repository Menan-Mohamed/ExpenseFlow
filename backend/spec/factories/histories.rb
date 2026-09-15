FactoryBot.define do
  factory :history do
    association :expense
    changer { nil }
    prev_state { :draft }
    next_state { :submitted }
    comment { "Expense submitted" }
  end
end

FactoryBot.define do
  factory :history do
    expense { nil }
    changer { nil }
    prev_state { 1 }
    next_state { 1 }
    comment { "MyText" }
  end
end

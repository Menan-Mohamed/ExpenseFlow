FactoryBot.define do
  factory :user do
    sequence(:email) { |number| "user#{number}@example.com" }
    password { "Password123!" }
    role { :employee }
    active { true }
  end
end

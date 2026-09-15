FactoryBot.define do
  factory :user do
    email { "MyString" }
    password_digest { "MyString" }
    role { 1 }
    active { false }
  end
end

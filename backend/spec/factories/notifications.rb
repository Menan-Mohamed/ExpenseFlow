FactoryBot.define do
  factory :notification do
    user { nil }
    content { "MyString" }
    is_read { false }
  end
end

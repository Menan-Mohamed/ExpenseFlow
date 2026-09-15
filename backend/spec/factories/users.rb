FactoryBot.define do
  factory :user do
    sequence(:email) { |number| "user#{number}@example.com" }
    password { "Password123!" }
    role { :employee }
    active { true }

    after(:build) do |user|
      if user.employee? && user.team.nil?
        manager = build(:user, role: :manager)
        user.team = build(:team, manager: manager)
      end
    end
  end
end

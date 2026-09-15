FactoryBot.define do
  factory :team do
    sequence(:name) { |number| "Team #{number}" }
    association :manager, factory: :user
  end
end

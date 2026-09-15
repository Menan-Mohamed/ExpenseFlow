require 'rails_helper'

RSpec.describe Category, type: :model do
  it "requires a name and a non-negative auto-approve limit" do
    category = build(:category, name: nil, auto_approve_limit: -1)

    expect(category).not_to be_valid
    expect(category.errors).to include(:name, :auto_approve_limit)
  end

  it "validates names without regard to case" do
    create(:category, name: "Travel")

    expect(build(:category, name: "travel")).not_to be_valid
  end

  it "restricts deletion when expenses exist" do
    category = create(:category)
    create(:expense, category: category)

    expect(category.destroy).to be(false)
    expect(category.errors[:base]).to be_present
  end
end

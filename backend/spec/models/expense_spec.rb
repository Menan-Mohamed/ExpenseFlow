require 'rails_helper'

RSpec.describe Expense, type: :model do
  it "starts as a draft with valid associations" do
    expense = build(:expense)

    expect(expense).to be_valid
    expect(expense).to be_draft
    expect(expense.user).to be_present
    expect(expense.category).to be_present
  end

  it "rejects inactive categories" do
    expense = build(:expense)
    expense.category.update!(active: false)

    expect(expense).not_to be_valid
    expect(expense.errors[:category]).to include("must be active")
  end

  it "rejects future dates and dates older than 90 days" do
    expense = build(:expense)
    expense.spent_date = Date.current + 1.day
    expect(expense).not_to be_valid
    expect(expense.errors[:spent_date]).to include("cannot be in the future")

    expense.spent_date = Date.current - 91.days
    expect(expense).not_to be_valid
    expect(expense.errors[:spent_date]).to include("cannot be more than 90 days before submission")
  end

  it "requires a positive amount no greater than 100000" do
    expect(build(:expense, amount: 0)).not_to be_valid
    expect(build(:expense, amount: 100_001)).not_to be_valid
  end

  it "destroys histories with the expense" do
    expense = create(:expense)
    history = create(:history, expense: expense)

    expect { expense.destroy }.to change(History, :count).by(-1)
    expect { history.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end

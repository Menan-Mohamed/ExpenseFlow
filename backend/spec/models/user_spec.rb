require 'rails_helper'

RSpec.describe User, type: :model do
  it "supports the defined roles and optional teams" do
    user = build(:user, role: :admin, team: nil)

    expect(user).to be_valid
    expect(user).to be_admin
  end

  it "requires unique email addresses case-insensitively" do
    create(:user, email: "person@example.com")

    expect(build(:user, email: "PERSON@example.com")).not_to be_valid
  end

  it "destroys associated expenses" do
    user = create(:user)
    expense = create(:expense, user: user)

    expect { user.destroy }.to change(Expense, :count).by(-1)
    expect { expense.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end

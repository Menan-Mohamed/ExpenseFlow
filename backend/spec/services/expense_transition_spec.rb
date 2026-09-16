require "rails_helper"

RSpec.describe ExpenseTransition, type: :service do
  let!(:category) { create(:category, auto_approve_limit: 50) }
  let!(:manager) { create(:user, role: :manager) }
  let!(:team) { create(:team, manager: manager) }
  let!(:employee) { create(:user, role: :employee, team: team) }
  let!(:admin) { create(:user, role: :admin) }

  def expense_for(amount)
    create(:expense, user: employee, category: category, amount: amount)
  end

  it "requires manager then admin approval for a high-value employee expense" do
    expense = expense_for(1_500)

    described_class.new(expense, actor: employee).submit!
    expect(expense.reload).to be_submitted
    expect(expense).to be_approval_stage_awaiting_manager

    described_class.new(expense, actor: manager).approve!(comment: "Reviewed by manager")
    expect(expense.reload).to be_submitted
    expect(expense).to be_approval_stage_awaiting_admin

    described_class.new(expense, actor: admin).approve!
    expect(expense.reload).to be_approved
    expect(expense).to be_approval_stage_not_applicable
  end

  it "does not allow admin to skip manager approval" do
    expense = expense_for(1_500)
    described_class.new(expense, actor: employee).submit!

    expect { described_class.new(expense, actor: admin).approve! }
      .to raise_error(ExpenseTransition::InvalidTransition, "requires manager approval")
  end

  it "does not allow a manager to finalize after manager approval" do
    expense = expense_for(1_500)
    described_class.new(expense, actor: employee).submit!
    described_class.new(expense, actor: manager).approve!

    expect { described_class.new(expense, actor: manager).approve! }
      .to raise_error(ExpenseTransition::InvalidTransition, "requires admin approval")
  end

  it "uses the single approval path below the two-level threshold" do
    expense = expense_for(100)
    described_class.new(expense, actor: employee).submit!

    expect(expense.reload).to be_submitted
    expect(expense).to be_approval_stage_not_applicable
    expect { described_class.new(expense, actor: manager).approve! }.not_to raise_error
    expect(expense.reload).to be_approved
  end

  it "does not allow an admin to review a below-threshold employee expense" do
    expense = expense_for(100)
    described_class.new(expense, actor: employee).submit!

    expect { described_class.new(expense, actor: admin).approve! }
      .to raise_error(ExpenseTransition::InvalidTransition, "requires manager approval")
  end
end

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

User.update_all(team_id: nil)
History.delete_all
Notification.delete_all
Expense.delete_all
Team.delete_all
User.delete_all
Category.delete_all
JwtDenylist.delete_all

# --- Users: every role, including a SECOND admin (needed so an admin's own
# expense can be reviewed by "a different admin", per Section 2) ---
admin1 = User.create!(email: "admin1@expenseflow.com", password: "1234", role: :admin, active: true)
admin2 = User.create!(email: "admin2@expenseflow.com", password: "1234", role: :admin, active: true)

# --- Two teams, two managers, one employee each — lets us prove a manager
# only sees/reviews their OWN team's members, not the other team's. ---
manager = User.create!(email: "manager@expenseflow.com", password: "1234", role: :manager, active: true)
team = Team.create!(name: "Engineering", manager: manager)
employee = User.create!(email: "employee@expenseflow.com", password: "1234", role: :employee, team: team, active: true)

manager2 = User.create!(email: "manager2@expenseflow.com", password: "1234", role: :manager, active: true)
team2 = Team.create!(name: "Sales", manager: manager2)
employee2 = User.create!(email: "employee2@expenseflow.com", password: "1234", role: :employee, team: team2, active: true)

# A deactivated user, to demo "deactivated user cannot sign in / loses access"
deactivated_employee = User.create!(email: "deactivated@expenseflow.com", password: "1234", role: :employee, team: team, active: false)

# --- Categories ---
travel = Category.create!(name: "Travel", auto_approve_limit: 30, active: true)
meals = Category.create!(name: "Meals", auto_approve_limit: 15, active: true)
equipment = Category.create!(name: "Equipment", auto_approve_limit: 0, active: true)
archived_category = Category.create!(name: "Legacy Misc", auto_approve_limit: 10, active: false)

# --- Expenses: one per state, across different owners/roles ---

# 1) DRAFT — untouched, owned by employee
draft_expense = Expense.create!(
  user: employee, category: travel, amount: 45,
  title: "Taxi fare (draft)", spent_date: Date.current - 2.days
)

# 2) AUTO-APPROVED via submit — amount <= category.auto_approve_limit (Meals limit 15)
auto_approved_expense = Expense.create!(
  user: employee, category: meals, amount: 12,
  title: "Coffee with client", spent_date: Date.current - 1.day
)
ExpenseTransition.new(auto_approved_expense, actor: employee).submit!

# 3) SUBMITTED — waiting on the employee's manager (amount above auto-approve limit)
submitted_expense = Expense.create!(
  user: employee, category: travel, amount: 120,
  title: "Flight ticket", spent_date: Date.current - 1.day
)
ExpenseTransition.new(submitted_expense, actor: employee).submit!

# 4) APPROVED — submitted then approved by the employee's manager
approved_expense = Expense.create!(
  user: employee, category: travel, amount: 200,
  title: "Hotel stay", spent_date: Date.current - 3.days
)
ExpenseTransition.new(approved_expense, actor: employee).submit!
ExpenseTransition.new(approved_expense, actor: manager).approve!(comment: "Looks good")

# 5) REJECTED — submitted then rejected by the manager (comment required)
rejected_expense = Expense.create!(
  user: employee, category: equipment, amount: 500,
  title: "Personal laptop upgrade", spent_date: Date.current - 4.days
)
ExpenseTransition.new(rejected_expense, actor: employee).submit!
ExpenseTransition.new(rejected_expense, actor: manager).reject!(comment: "Not a business expense, please clarify")

# 6) REIMBURSED — submitted, approved, then reimbursed by an admin
reimbursed_expense = Expense.create!(
  user: employee, category: travel, amount: 80,
  title: "Train ticket", spent_date: Date.current - 5.days
)
ExpenseTransition.new(reimbursed_expense, actor: employee).submit!
ExpenseTransition.new(reimbursed_expense, actor: manager).approve!
ExpenseTransition.new(reimbursed_expense, actor: admin1).reimburse!(payment_reference: "PMT-1001")

# 7) SUBMITTED, on team2 — waiting on manager2, NOT manager.
team2_submitted_expense = Expense.create!(
  user: employee2, category: travel, amount: 90,
  title: "Client dinner (team2)", spent_date: Date.current - 1.day
)
ExpenseTransition.new(team2_submitted_expense, actor: employee2).submit!

# 8) FULL REOPEN CYCLE: draft -> submitted -> rejected -> draft -> submitted -> approved
# Proves `reopen!` correctly returns an expense to draft after rejection, and that
# it can be resubmitted and approved normally afterward.
reopened_expense = Expense.create!(
  user: employee, category: equipment, amount: 400,
  title: "Standing desk", spent_date: Date.current - 6.days
)
ExpenseTransition.new(reopened_expense, actor: employee).submit!                                    # draft -> submitted
ExpenseTransition.new(reopened_expense, actor: manager).reject!(comment: "Need a cheaper alternative") # submitted -> rejected
ExpenseTransition.new(reopened_expense, actor: employee).reopen!                                    # rejected -> draft
reopened_expense.update!(amount: 250, title: "Standing desk (cheaper model)")                        # owner fixes it, still draft
ExpenseTransition.new(reopened_expense, actor: employee).submit!                                    # draft -> submitted (again)
ExpenseTransition.new(reopened_expense, actor: manager).approve!(comment: "Better price, approved")   # submitted -> approved

# 9) TWO-LEVEL APPROVAL : draft -> submitted -> manager approval -> admin approval
# Amount must exceed TWO_LEVEL_APPROVAL_THRESHOLD (see config/application.rb) to
# trigger the manager-then-admin flow instead of a single-reviewer approval.
two_level_expense = Expense.create!(
  user: employee, category: equipment, amount: 1500,
  title: "New company laptop", spent_date: Date.current - 2.days
)
ExpenseTransition.new(two_level_expense, actor: employee).submit!                       # draft -> submitted, awaiting_manager
ExpenseTransition.new(two_level_expense, actor: manager).approve!(comment: "Manager sign-off") # stays submitted, awaiting_admin
ExpenseTransition.new(two_level_expense, actor: admin1).approve!(comment: "Admin sign-off")    # submitted -> approved

# --- Self-review rule coverage: manager's and admin's own expenses ---

# Manager's own expense — reviewed by an admin (never their own team)
manager_expense = Expense.create!(
  user: manager, category: travel, amount: 150,
  title: "Conference travel", spent_date: Date.current - 2.days
)
ExpenseTransition.new(manager_expense, actor: manager).submit!
ExpenseTransition.new(manager_expense, actor: admin1).approve!(comment: "Approved for conference")

# Admin's own expense — reviewed by a DIFFERENT admin
admin_expense = Expense.create!(
  user: admin1, category: equipment, amount: 300,
  title: "New monitor", spent_date: Date.current - 1.day
)
ExpenseTransition.new(admin_expense, actor: admin1).submit!
ExpenseTransition.new(admin_expense, actor: admin2).approve!(comment: "Approved by second admin")

puts "Seeded #{User.count} users, #{Team.count} teams, #{Category.count} categories, " \
     "#{Expense.count} expenses, #{History.count} history rows, #{Notification.count} notifications."
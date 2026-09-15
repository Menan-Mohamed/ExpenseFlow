# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
User.update_all(team_id: nil)
History.delete_all
Notification.delete_all
Expense.delete_all
Team.delete_all      
User.delete_all
Category.delete_all

admin1 = User.create!(email: "admin1@expenseflow.com", password: "1234", role: :admin, active: true)
admin2 = User.create!(email: "admin2@expenseflow.com", password: "1234", role: :admin, active: true)

manager = User.create!(email: "manager@expenseflow.com", password: "1234", role: :manager, active: true)
team = Team.create!(name: "Engineering", manager: manager)
manager.update!(team: team)

employee = User.create!(email: "employee@expenseflow.com", password: "1234", role: :employee, team: team, active: true)

travel = Category.create!(name: "Travel", auto_approve_limit: 50, active: true)

expense1 = Expense.create!(user: employee, category: travel, amount: 30, title: "Taxi fare", spent_date: Date.today - 2.days)
expense2 = Expense.create!(user: employee, category: travel, amount: 100, title: "Flight ticket", spent_date: Date.today - 1.day)
expense3 = Expense.create!(user: employee, category: travel, amount: 20, title: "Lunch with client", spent_date: Date.today - 1.day)
expense4 = Expense.create!(user: employee, category: travel, amount: 200, title: "Hotel stay", spent_date: Date.today - 1.day)
expense5 = Expense.create!(user: employee, category: travel, amount: 10, title: "Parking fee", spent_date: Date.today - 1.day)
expense6 = Expense.create!(user: employee, category: travel, amount: 60, title: "Train ticket", spent_date: Date.today - 1.day)
expense7 = Expense.create!(user: employee, category: travel, amount: 15, title: "Coffee with client", spent_date: Date.today - 1.day)
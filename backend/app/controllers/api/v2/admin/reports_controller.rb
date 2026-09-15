module Api
  module V2
    module Admin
      class ReportsController < AdminController
        def show
          expenses = Expense.all
          expenses = expenses.where(spent_date: Date.parse(params[:from])..Date.parse(params[:to])) if params[:from].present? && params[:to].present?
          expenses = expenses.where(state: params[:state]) if Expense.states.key?(params[:state])
          render json: {
            generated_at: Time.current,
            filters: { from: params[:from], to: params[:to], state: params[:state] },
            summary: { total_expenses: expenses.count, total_amount: expenses.sum(:amount), reimbursed_amount: expenses.where(state: :reimbursed).sum(:amount) },
            by_state: expenses.group(:state).count,
            by_category: expenses.joins(:category).group("categories.name").sum(:amount)
          }
        rescue Date::Error
          render json: { error: "Invalid report date range" }, status: :unprocessable_entity
        end
      end
    end
  end
end
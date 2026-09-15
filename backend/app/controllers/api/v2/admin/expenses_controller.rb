module Api
  module V2
    module Admin
      class ExpensesController < AdminController
        def index
          expenses = Expense.includes(:user, :category)
            .where.not(user_id: current_user.id)
            .where.not(state: :draft)
            .order(spent_date: :desc, created_at: :desc)
          expenses = expenses.where(state: params[:state]) if Expense.states.key?(params[:state])
          expenses = expenses.joins(:user).where("expenses.title ILIKE ? OR users.email ILIKE ?", "%#{search}%", "%#{search}%") if params[:search].present?
          expenses, meta = pagination(expenses)
          render json: { expenses: expenses.map { |expense| expense_response(expense) }, pagination: meta }
        end

        def show
          expense = Expense.includes(:user, :category, histories: :changer).find(params[:id])
          render json: expense_response(expense).merge(history: expense.histories.order(created_at: :desc).map { |history| history_response(history) })
        end

        def reimburse
          expense = Expense.find(params[:id])
          ExpenseTransition.new(expense, actor: current_user).reimburse!(payment_reference: params.require(:payment_reference))
          render json: expense_response(expense)
        rescue ExpenseTransition::InvalidTransition, ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        def approve
          review_expense { |expense| ExpenseTransition.new(expense, actor: current_user).approve!(comment: params[:comment]) }
        end

        def reject
          review_expense { |expense| ExpenseTransition.new(expense, actor: current_user).reject!(comment: params.require(:comment)) }
        end

        private

        def search
          "%#{Expense.sanitize_sql_like(params[:search])}%"
        end

        def review_expense
          expense = Expense.joins(:user)
            .where(users: { role: [User.roles[:employee], User.roles[:manager]] })
            .where.not(user_id: current_user.id)
            .find(params[:id])
          yield expense
          render json: expense_response(expense)
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Expense not found" }, status: :not_found
        rescue ExpenseTransition::InvalidTransition, ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        def expense_response(expense)
          { id: expense.id, title: expense.title, description: expense.description, amount: expense.amount, category_id: expense.category_id, category_name: expense.category.name, user_id: expense.user_id, user_email: expense.user.email, user_role: expense.user.role, spent_date: expense.spent_date, state: expense.state, payment_reference: expense.payment_reference, created_at: expense.created_at, updated_at: expense.updated_at }
        end

        def history_response(history)
          { id: history.id, prev_state: history.prev_state, next_state: history.next_state, comment: history.comment, changed_by: history.changer&.email, created_at: history.created_at }
        end
      end
    end
  end
end
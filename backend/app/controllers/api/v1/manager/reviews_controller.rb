module Api
  module V1
    module Manager
      class ReviewsController < ManagerController
        before_action :set_review, only: [:show, :approve, :reject]

        def index
          expenses = Expense.includes(:user, :category)
            .joins(user: :team)
            .where(users: { team_id: managed_team.id, role: User.roles[:employee] })
            .where.not(state: :draft)
            .order(created_at: :desc)
          expenses = expenses.where(state: params[:state]) if Expense.states.key?(params[:state])
          expenses, meta = pagination(expenses)
          render json: { expenses: expenses.map { |expense| expense_response(expense) }, pagination: meta }
        end

        def show
          render json: expense_response(@expense).merge(history: history_response(@expense))
        end

        def approve
          ExpenseTransition.new(@expense, actor: current_user).approve!(comment: params[:comment])
          render json: expense_response(@expense)
        rescue ExpenseTransition::InvalidTransition => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        def reject
          ExpenseTransition.new(@expense, actor: current_user).reject!(comment: params[:comment])
          render json: expense_response(@expense)
        rescue ExpenseTransition::InvalidTransition, ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        def set_review
          @expense = Expense.joins(user: :team)
            .where(users: { team_id: managed_team.id, role: User.roles[:employee] })
            .where.not(state: :draft)
            .find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Expense not found" }, status: :not_found
        end

        def expense_response(expense)
          { id: expense.id, title: expense.title, description: expense.description, amount: expense.amount, payment_reference: expense.payment_reference, category_id: expense.category_id, category_name: expense.category.name, user_id: expense.user_id, user_email: expense.user.email, spent_date: expense.spent_date, state: expense.state, approval_stage: expense.approval_stage, created_at: expense.created_at, updated_at: expense.updated_at }
        end

        def history_response(expense)
          expense.histories.includes(:changer).order(created_at: :desc).map do |history|
            { id: history.id, prev_state: history.prev_state, next_state: history.next_state, comment: history.comment, changed_by: history.changer&.email, created_at: history.created_at }
          end
        end
      end
    end
  end
end
module Api
  module V2
    module Manager
      class ExpensesController < ManagerController
        before_action :set_expense, only: [:show, :update, :destroy, :submit]
        before_action :ensure_draft, only: [:update, :destroy, :submit]

        def index
          expenses = current_user.expenses.includes(:category).order(spent_date: :desc, created_at: :desc)
          expenses, meta = pagination(expenses)
          render json: { expenses: expenses.map { |expense| expense_response(expense) }, pagination: meta }
        end

        def show
          render json: expense_response(@expense).merge(history: history_response(@expense))
        end

        def create
          expense = current_user.expenses.new(expense_params.merge(state: :draft))
          if expense.save
            render json: expense_response(expense), status: :created
          else
            render_validation_errors(expense)
          end
        end

        def update
          if @expense.update(expense_params)
            render json: expense_response(@expense)
          else
            render_validation_errors(@expense)
          end
        end

        def destroy
          @expense.destroy!
          head :no_content
        end

        def submit
          ExpenseTransition.new(@expense, actor: current_user).submit!
          render json: expense_response(@expense)
        rescue ExpenseTransition::InvalidTransition => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        def set_expense
          @expense = current_user.expenses.includes(:category).find_by(id: params[:id])
          return if @expense

          render json: { error: "Expense not found" }, status: :not_found
        end

        def ensure_draft
          return if performed? || @expense.draft?

          render json: { error: "Only draft expenses can be changed" }, status: :unprocessable_entity
        end

        def expense_params
          params.require(:expense).permit(:title, :description, :amount, :category_id, :spent_date)
        end

        def expense_response(expense)
          { id: expense.id, title: expense.title, description: expense.description, amount: expense.amount, payment_reference: expense.payment_reference, category_id: expense.category_id, category_name: expense.category.name, spent_date: expense.spent_date, state: expense.state, created_at: expense.created_at, updated_at: expense.updated_at }
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
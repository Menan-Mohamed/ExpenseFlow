class SubmitExpenseService
  def self.call(expense:, changer:)
    new(expense: expense, changer: changer).call
  end

  def initialize(expense:, changer:)
    @expense = expense
    @changer = changer
  end

  def call
    @expense.with_lock do
      previous_state = Expense.states.fetch(@expense.state)
      next_state = Expense.states.fetch("submitted")

      @expense.update!(state: :submitted)
      History.create!(
        expense: @expense,
        changer: @changer,
        prev_state: previous_state,
        next_state: next_state,
        comment: "Expense submitted"
      )
    end

    @expense
  end
end

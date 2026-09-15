class ExpenseTransition
  class InvalidTransition < StandardError; end

  def initialize(expense, actor:)
    @expense = expense
    @actor = actor
  end

  def submit!
    raise InvalidTransition, "must be draft" unless expense.draft?
    raise InvalidTransition, "only the owner can submit" unless actor == expense.user

    expense.with_lock do
      if expense.auto_approvable?
        record_history(to: "approved", by: nil, comment: nil) # nil = system
        expense.update!(state: :approved)
      else
        record_history(to: "submitted", by: actor, comment: nil)
        expense.update!(state: :submitted)
      end
    end

    notify_owner("Your expense '#{expense.title}' is now #{expense.state}.")
    expense
  end

  def approve!(comment: nil)
    authorize_review!

    expense.with_lock do
      record_history(to: "approved", by: actor, comment: comment)
      expense.update!(state: :approved)
    end

    notify_owner("Your expense '#{expense.title}' was approved.")
    expense
  end

  def reject!(comment:)
    raise InvalidTransition, "comment is required" if comment.blank?
    authorize_review!

    expense.with_lock do
      record_history(to: "rejected", by: actor, comment: comment)
      expense.update!(state: :rejected)
    end

    notify_owner("Your expense '#{expense.title}' was rejected: #{comment}")
    expense
  end

  def reopen!
    raise InvalidTransition, "must be rejected" unless expense.rejected?
    raise InvalidTransition, "only the owner can reopen" unless actor == expense.user

    expense.with_lock do
      record_history(to: "draft", by: actor, comment: nil)
      expense.update!(state: :draft)
    end

    expense
  end

  def reimburse!(payment_reference:)
    raise InvalidTransition, "payment reference required" if payment_reference.blank?
    raise InvalidTransition, "must be approved" unless expense.approved?
    raise InvalidTransition, "only admins can reimburse" unless actor.admin?

    expense.with_lock do
      record_history(to: "reimbursed", by: actor, comment: nil)
      expense.update!(state: :reimbursed, payment_reference: payment_reference)
    end

    notify_owner("Your expense '#{expense.title}' was reimbursed.")
    expense
  end

  private

  attr_reader :expense, :actor

  def authorize_review!
    raise InvalidTransition, "must be submitted" unless expense.submitted?
    raise InvalidTransition, "not an eligible reviewer" unless expense.eligible_reviewer?(actor)
  end

  # Reads @expense.state BEFORE the caller updates it, so prev_state is always
  # accurate regardless of which transition is calling this.
  def record_history(to:, by:, comment:)
    previous_state = Expense.states.fetch(expense.state)
    next_state = Expense.states.fetch(to)

    History.create!(
      expense: expense,
      changer: by,
      prev_state: previous_state,
      next_state: next_state,
      comment: comment
    )
  end

  def notify_owner(content)
    Notification.create!(user: expense.user, content: content)
  end
end
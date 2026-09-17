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
        expense.update!(state: :approved, approval_stage: :not_applicable)
      elsif expense.requires_two_level_approval?
        record_history(to: "submitted", by: actor, comment: nil)
        expense.update!(state: :submitted, approval_stage: :awaiting_manager)
      else
        record_history(to: "submitted", by: actor, comment: nil)
        expense.update!(state: :submitted, approval_stage: :not_applicable)
      end
    end

    notify_owner("Your expense '#{expense.title}' is now #{expense.state}.")
    expense
  end

  def approve!(comment: nil)
    raise InvalidTransition, "must be submitted" unless expense.submitted?

    if expense.approval_stage_awaiting_manager?
      raise InvalidTransition, "requires manager approval" unless actor.manager? && expense.eligible_reviewer?(actor)

      expense.with_lock do
        record_history(to: "submitted", by: actor, comment: comment.presence || "Manager approval (stage 1 of 2)")
        expense.update!(approval_stage: :awaiting_admin)
      end

      notify_owner("Your expense '#{expense.title}' received manager approval, awaiting admin.")
      return expense
    end

    if expense.approval_stage_awaiting_admin?
      raise InvalidTransition, "requires admin approval" unless actor.admin? && expense.eligible_reviewer?(actor)
    end

    if expense.user.employee? && expense.approval_stage_not_applicable?
      raise InvalidTransition, "requires manager approval" unless actor.manager? && expense.eligible_reviewer?(actor)
    end

    raise InvalidTransition, "not an eligible reviewer" unless expense.eligible_reviewer?(actor)

    expense.with_lock do
      record_history(to: "approved", by: actor, comment: comment)
      expense.update!(state: :approved, approval_stage: :not_applicable)
    end

    notify_owner("Your expense '#{expense.title}' was approved.")
    expense
  end

  def reject!(comment:)
    raise InvalidTransition, "comment is required" if comment.blank?
    raise InvalidTransition, "must be submitted" unless expense.submitted?

    if expense.approval_stage_awaiting_manager?
      raise InvalidTransition, "requires manager review" unless actor.manager? && expense.eligible_reviewer?(actor)
    elsif expense.approval_stage_awaiting_admin?
      raise InvalidTransition, "requires admin review" unless actor.admin? && expense.eligible_reviewer?(actor)
    elsif expense.user.employee? && expense.approval_stage_not_applicable?
      raise InvalidTransition, "requires manager review" unless actor.manager? && expense.eligible_reviewer?(actor)
    elsif !expense.eligible_reviewer?(actor)
      raise InvalidTransition, "not an eligible reviewer"
    end

    expense.with_lock do
      record_history(to: "rejected", by: actor, comment: comment)
      expense.update!(state: :rejected, approval_stage: :not_applicable)
    end

    notify_owner("Your expense '#{expense.title}' was rejected: #{comment}")
    expense
  end

  def reopen!
    raise InvalidTransition, "must be rejected" unless expense.rejected?
    raise InvalidTransition, "only the owner can reopen" unless actor == expense.user

    expense.with_lock do
      record_history(to: "draft", by: actor, comment: nil)
      expense.update!(state: :draft, approval_stage: :not_applicable)
    end

    expense
  end

  def reimburse!(payment_reference:)
    raise InvalidTransition, "payment reference required" if payment_reference.blank?
    raise InvalidTransition, "must be approved" unless expense.approved?
    raise InvalidTransition, "only admins can reimburse" unless actor.admin?
    raise InvalidTransition, "Can't reimburse it's own expense" if actor == expense.user

    expense.with_lock do
      record_history(to: "reimbursed", by: actor, comment: nil)
      expense.update!(state: :reimbursed, payment_reference: payment_reference)
    end

    notify_owner("Your expense '#{expense.title}' was reimbursed.")
    expense
  end

  private

  attr_reader :expense, :actor

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
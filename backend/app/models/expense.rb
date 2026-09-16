class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :histories, dependent: :destroy
  enum state: { draft: 0, submitted: 1, approved: 2, rejected: 3, reimbursed: 4 }
  enum approval_stage: { not_applicable: 0, awaiting_manager: 1, awaiting_admin: 2 }, _prefix: true

  validates :title, presence: true
  validates :amount, numericality: { greater_than: 0, less_than_or_equal_to: 100_000 }
  validates :spent_date, presence: true
  validate :spent_date_is_not_in_the_future
  validate :spent_date_is_within_submission_window
  validate :category_is_active

  
  def auto_approvable?
    amount <= category.auto_approve_limit
  end

  def requires_two_level_approval?
    user.employee? && amount > Rails.application.config.x.expense_two_level_approval_threshold
  end

  def eligible_reviewer?(reviewer)
    return false if reviewer == user # nobody reviews their own expense

    if user.employee?
      return reviewer.admin? if approval_stage_awaiting_admin?

      reviewer.manager? && user.team&.manager_id == reviewer.id
    elsif user.manager? || user.admin?
      reviewer.admin?
    else
      false
    end
  end

  private

  def spent_date_is_not_in_the_future
    return if spent_date.blank? || spent_date <= Date.current

    errors.add(:spent_date, "cannot be in the future")
  end

  def spent_date_is_within_submission_window
    return if spent_date.blank?

    submission_date = created_at&.to_date || Date.current
    return if spent_date >= submission_date - 90.days

    errors.add(:spent_date, "cannot be more than 90 days before submission")
  end

  def category_is_active
    return if category&.active?

    errors.add(:category, "must be active")
  end

end

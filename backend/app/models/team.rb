class Team < ApplicationRecord
  belongs_to :manager, class_name: "User"
  has_many :users, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validate :manager_must_have_manager_role
  validate :manager_must_not_already_manage_a_team

  private

  def manager_must_have_manager_role
    return if manager.blank?

    errors.add(:manager, "must have the manager role") unless manager.manager?
  end

  def manager_must_not_already_manage_a_team
    return if manager.blank?

    existing = Team.where(manager_id: manager.id)
    existing = existing.where.not(id: id) if persisted?

    errors.add(:manager, "is already assigned to another team") if existing.exists?
  end
end
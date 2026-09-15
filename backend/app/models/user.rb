class User < ApplicationRecord
  has_secure_password
  belongs_to :team, optional: true
  has_one :managed_team, class_name: "Team", foreign_key: "manager_id"
  has_many :expenses, dependent: :destroy
  enum role: { employee: 0, manager: 1, admin: 2 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
end

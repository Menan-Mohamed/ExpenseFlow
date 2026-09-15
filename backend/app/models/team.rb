class Team < ApplicationRecord
  belongs_to :manager, class_name: "User"
  has_many :users, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
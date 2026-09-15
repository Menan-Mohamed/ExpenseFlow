class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category
  enum state: { draft: 0, submitted: 1, approved: 2, rejected: 3, reimbursed: 4 }
end

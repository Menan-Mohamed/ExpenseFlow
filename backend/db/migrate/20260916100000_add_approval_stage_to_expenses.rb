class AddApprovalStageToExpenses < ActiveRecord::Migration[7.1]
  def change
    add_column :expenses, :approval_stage, :integer, null: false, default: 0
    add_index :expenses, :approval_stage
  end
end
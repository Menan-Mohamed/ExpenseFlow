class AddDefaultStateToExpenses < ActiveRecord::Migration[7.1]
  def change
    change_column_default :expenses, :state, from: nil, to: 0
  end
end

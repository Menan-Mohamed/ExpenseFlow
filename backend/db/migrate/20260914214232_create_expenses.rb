class CreateExpenses < ActiveRecord::Migration[7.1]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.decimal :amount
      t.date :spent_date
      t.integer :state
      t.string :payment_reference

      t.timestamps
    end
  end
end

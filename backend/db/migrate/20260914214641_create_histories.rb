class CreateHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :histories do |t|
      t.references :expense, null: false, foreign_key: true
      t.references :changer, null: true, foreign_key: { to_table: :users }
      t.integer :prev_state
      t.integer :next_state
      t.text :comment
      t.timestamps
    end
  end
end
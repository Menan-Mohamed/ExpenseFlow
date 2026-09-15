class AddManagerToTeams < ActiveRecord::Migration[7.1]
  def change
    add_reference :teams, :manager, foreign_key: { to_table: :users }
  end
end
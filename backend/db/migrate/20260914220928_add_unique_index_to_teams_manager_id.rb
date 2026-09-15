class AddUniqueIndexToTeamsManagerId < ActiveRecord::Migration[7.1]
  def change
    remove_index :teams, :manager_id
    add_index :teams, :manager_id, unique: true
  end
end

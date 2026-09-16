class DefaultNotificationsToUnread < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE notifications SET is_read = FALSE WHERE is_read IS NULL"
    change_column_default :notifications, :is_read, from: nil, to: false
    change_column_null :notifications, :is_read, false
  end

  def down
    change_column_null :notifications, :is_read, true
    change_column_default :notifications, :is_read, from: false, to: nil
  end
end
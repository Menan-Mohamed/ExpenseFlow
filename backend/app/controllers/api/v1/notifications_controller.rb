module Api
  module V1
    class NotificationsController < ApplicationController
      def index
        notifications = current_user.notifications.unread.order(created_at: :desc)

        Notification.transaction do
          @notifications = notifications.to_a
          Notification.where(id: @notifications.map(&:id)).update_all(is_read: true, updated_at: Time.current)
        end

        render json: @notifications.map { |notification| notification_response(notification) }
      end

      private

      def notification_response(notification)
        { id: notification.id, content: notification.content, created_at: notification.created_at }
      end
    end
  end
end
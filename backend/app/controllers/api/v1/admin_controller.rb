module Api
  module V1
    class AdminController < ApplicationController
      before_action :ensure_admin

      private

      def ensure_admin
        return if current_user.admin?

        render json: { error: "Admin access required" }, status: :forbidden
      end

      def pagination(scope)
        page = [params.fetch(:page, 1).to_i, 1].max
        per_page = [[params.fetch(:per_page, 5).to_i, 1].max, 50].min
        total_count = scope.count
        [scope.offset((page - 1) * per_page).limit(per_page), {
          page: page,
          per_page: per_page,
          total_count: total_count,
          total_pages: (total_count.to_f / per_page).ceil
        }]
      end

      def render_validation_errors(record)
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
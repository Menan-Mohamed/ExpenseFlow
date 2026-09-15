module Api
  module V2
    module Admin
      class UsersController < AdminController
        def index
          users = User.includes(:team).order(sort_column => sort_direction)
          if params[:search].present?
            users = users.where("users.email ILIKE ?", "%#{User.sanitize_sql_like(params[:search])}%")
          end
          users = users.where(role: params[:role]) if User.roles.key?(params[:role])
          users, meta = pagination(users)
          render json: { users: users.map { |user| user_response(user) }, pagination: meta }
        end

        def create
          user = User.new(user_params)
          if user.save
            render json: user_response(user), status: :created
          else
            render_validation_errors(user)
          end
        end

        def update
          user = User.find(params[:id])
          if user.update(user_params)
            render json: user_response(user)
          else
            render_validation_errors(user)
          end
        end

        def activate
          update_status(true)
        end

        def deactivate
          update_status(false)
        end

        private

        def user_params
          permitted = params.require(:user).permit(:email, :password, :role, :team_id)
          permitted.delete(:password) if permitted[:password].blank?
          permitted
        end

        def update_status(active)
          user = User.find(params[:id])
          if user.update(active: active)
            render json: user_response(user)
          else
            render_validation_errors(user)
          end
        end

        def sort_column
          %w[email role active created_at].include?(params[:sort]) ? params[:sort] : "created_at"
        end

        def sort_direction
          params[:direction] == "asc" ? :asc : :desc
        end

        def user_response(user)
          { id: user.id, email: user.email, role: user.role, active: user.active, team_id: user.team_id, team_name: user.team&.name }
        end
      end
    end
  end
end
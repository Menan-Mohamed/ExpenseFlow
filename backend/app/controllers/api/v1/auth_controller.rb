module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [:login]

      def login
        user = User.find_by("lower(email) = ?", params[:email]&.downcase)

        if user&.active? && user.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: user_response(user) }, status: :ok
        else
          render json: { error: "Invalid credentials" }, status: :unauthorized
        end
      end

      def logout
        JwtDenylist.create!(jti: current_jti, expires_at: current_exp)
        head :no_content
      end

      private

      def user_response(user)
        { id: user.id, email: user.email, role: user.role, team_id: user.team_id }
      end
    end
  end
end
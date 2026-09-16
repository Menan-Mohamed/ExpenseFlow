module Api
  module V1
    class MeController < ApplicationController
      def show
        render json: {
          id: current_user.id,
          email: current_user.email,
          role: current_user.role,
          team_id: current_user.team_id,
          team_name: current_user.team&.name
        }
      end
    end
  end
end
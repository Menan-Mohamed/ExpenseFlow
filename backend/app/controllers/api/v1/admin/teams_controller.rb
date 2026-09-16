module Api
  module V1
    module Admin
      class TeamsController < AdminController
        def index
          teams, meta = pagination(Team.includes(:manager).order(:name))
          render json: { teams: teams.map { |team| team_response(team) }, pagination: meta }
        end

        def create
          team = Team.new(team_params)

          Team.transaction do
           team.save!
            manager = User.find(team.manager_id)
            manager.update!(team: team)
          end

          render json: team_response(team), status: :created
        rescue ActiveRecord::RecordInvalid => error
          render_validation_errors(error.record)
        end

        def update
          team = Team.find(params[:id])
          if team.update(team_params)
            render json: team_response(team)
          else
            render_validation_errors(team)
          end
        end

        def destroy
          Team.find(params[:id]).destroy!
          head :no_content
        rescue ActiveRecord::RecordNotDestroyed => e
          render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
        end

        private

        def team_params
          params.require(:team).permit(:name, :manager_id)
        end

        def team_response(team)
          { id: team.id, name: team.name, manager_id: team.manager_id, manager_email: team.manager&.email }
        end
      end
    end
  end
end
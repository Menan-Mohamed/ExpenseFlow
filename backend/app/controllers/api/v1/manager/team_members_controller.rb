module Api
  module V1
    module Manager
      class TeamMembersController < ManagerController
        def index
          members, meta = pagination(managed_team.users.where(role: :employee).order(:email))
          render json: { users: members.map { |user| { id: user.id, email: user.email, role: user.role, active: user.active, team_id: user.team_id } }, pagination: meta }
        end
      end
    end
  end
end
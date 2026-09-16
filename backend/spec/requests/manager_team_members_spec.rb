require "rails_helper"

RSpec.describe "Manager team members API", type: :request do
  let!(:manager) { create(:user, role: :manager, email: "team-manager@example.com") }
  let!(:team) { create(:team, manager: manager) }
  let!(:employee) { create(:user, role: :employee, team: team, email: "team-employee@example.com") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" }
  end

  it "returns employees assigned to the manager's team" do
    get "/api/v1/manager/team_members", headers: auth_headers(manager)

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch("users")).to include(
      a_hash_including("id" => employee.id, "email" => employee.email, "role" => "employee", "team_id" => team.id)
    )
  end
end

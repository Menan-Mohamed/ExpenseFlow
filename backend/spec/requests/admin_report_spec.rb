require "rails_helper"

RSpec.describe "Admin reports API", type: :request do
  let!(:admin) { create(:user, role: :admin, email: "report-admin@example.com") }
  let!(:employee) { create(:user, role: :employee, email: "report-employee@example.com") }
  let!(:category) { create(:category, name: "Travel") }
  let!(:other_category) { create(:category, name: "Meals") }
  let(:from) { Date.current.beginning_of_month.iso8601 }
  let(:to) { Date.current.end_of_month.iso8601 }

  def auth_headers(user)
    { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" }
  end

  it "returns approved and reimbursed totals by month and category" do
    create(:expense, user: employee, category: category, amount: 100, state: :approved, spent_date: Date.current)
    create(:expense, user: employee, category: category, amount: 75, state: :reimbursed, spent_date: Date.current)
    create(:expense, user: employee, category: other_category, amount: 40, state: :approved, spent_date: Date.current - 1.month)

    get "/api/v1/admin/report", params: { from: from, to: to }, headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    expect(json_response.fetch("rows")).to include(
      a_hash_including("month" => Date.current.strftime("%Y-%m"), "category" => "Travel", "approved_count" => 1, "approved_amount" => "100.0", "reimbursed_count" => 1, "reimbursed_amount" => "75.0")
    )
    expect(json_response.dig("summary", "total_expenses")).to eq(2)
  end

  it "returns the report as CSV" do
    get "/api/v1/admin/report.csv", params: { from: from, to: to }, headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.body).to include("Month,Category,Approved count,Approved amount,Reimbursed count,Reimbursed amount")
  end

  it "rejects a missing or reversed date range" do
    get "/api/v1/admin/report", params: { from: to, to: from }, headers: auth_headers(admin)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)).to eq("error" => "Invalid report date range")
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end

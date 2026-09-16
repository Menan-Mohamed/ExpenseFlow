require "rails_helper"

RSpec.describe "ExpenseFlow API", type: :request do
  let!(:employee) { create(:user, email: "employee@example.com", password: "Password123!", role: :employee) }
  let!(:manager) { create(:user, email: "manager@example.com", password: "Password123!", role: :manager) }
  let!(:category) { create(:category, name: "Travel") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" }
  end

  def json_response
    JSON.parse(response.body)
  end

  describe "POST /api/v1/auth/login" do
    it "returns a token for active users" do
      post "/api/v1/auth/login", params: { email: employee.email, password: "Password123!" }

      expect(response).to have_http_status(:ok)
      expect(json_response).to include("token")
      expect(json_response["user"]).to include("id" => employee.id, "email" => employee.email)
    end

    it "rejects invalid credentials" do
      post "/api/v1/auth/login", params: { email: employee.email, password: "wrong" }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to eq("error" => "Invalid credentials")
    end
  end

  describe "authenticated v1 endpoints" do
    it "returns the current user" do
      get "/api/v1/me", headers: auth_headers(employee)

      expect(response).to have_http_status(:ok)
      expect(json_response).to include("id" => employee.id, "email" => employee.email)
    end

    it "rejects missing authentication" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to eq("error" => "Unauthorized")
    end

    it "revokes a token at logout" do
      token = JsonWebToken.encode(user_id: employee.id)
      headers = { "Authorization" => "Bearer #{token}" }

      delete "/api/v1/auth/logout", headers: headers
      get "/api/v1/me", headers: headers

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/categories" do
    it "returns active categories in name order" do
      create(:category, name: "Archived", active: false)
      create(:category, name: "Meals")

      get "/api/v1/categories", headers: auth_headers(employee)

      expect(response).to have_http_status(:ok)
      expect(json_response.map { |item| item["name"] }).to eq(["Meals", "Travel"])
    end
  end

  describe "expense endpoints" do
    it "creates, lists, updates, and deletes a draft expense" do
      payload = { expense: { title: "Flight", description: "Client visit", amount: 250, category_id: category.id, spent_date: Date.current } }

      post "/api/v1/expenses", params: payload, headers: auth_headers(employee)
      expect(response).to have_http_status(:created)
      expense_id = json_response.fetch("id")
      expect(json_response).to include("title" => "Flight", "state" => "draft", "category_name" => "Travel")

      get "/api/v1/expenses", params: { page: 1, per_page: 5 }, headers: auth_headers(employee)
      expect(response).to have_http_status(:ok)
      expect(json_response["expenses"].map { |item| item["id"] }).to include(expense_id)
      expect(json_response["pagination"]).to include("page" => 1, "per_page" => 5, "total_count" => 1, "total_pages" => 1)

      patch "/api/v1/expenses/#{expense_id}", params: { expense: { title: "Updated flight" } }, headers: auth_headers(employee)
      expect(response).to have_http_status(:ok)
      expect(json_response["title"]).to eq("Updated flight")

      delete "/api/v1/expenses/#{expense_id}", headers: auth_headers(employee)
      expect(response).to have_http_status(:no_content)
    end

    it "shows history after submitting an expense" do
      expense = create(:expense, user: employee, category: category)

      post "/api/v1/expenses/#{expense.id}/submit", headers: auth_headers(employee)
      expect(response).to have_http_status(:ok)
      expect(json_response).to include("state" => "submitted")

      get "/api/v1/expenses/#{expense.id}", headers: auth_headers(employee)
      expect(response).to have_http_status(:ok)
      expect(json_response["history"].first).to include("prev_state" => 0, "next_state" => 1, "changed_by" => employee.email)
    end

    it "prevents managers from managing expenses" do
      get "/api/v1/expenses", headers: auth_headers(manager)

      expect(response).to have_http_status(:forbidden)
      expect(json_response).to eq("error" => "Only employees can manage expenses")
    end

    it "does not expose another employee's expense" do
      other_expense = create(:expense, category: category)

      get "/api/v1/expenses/#{other_expense.id}", headers: auth_headers(employee)

      expect(response).to have_http_status(:not_found)
      expect(json_response).to eq("error" => "Expense not found")
    end
  end
end

require "swagger_helper"

RSpec.describe "ExpenseFlow API", type: :request do
  let!(:employee) { create(:user, email: "swagger@example.com", password: "Password123!", role: :employee) }
  let!(:category) { create(:category, name: "Swagger category") }
  let!(:expense) { create(:expense, user: employee, category: category) }
  let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: employee.id)}" }

  path "/api/v1/auth/login" do
    post "Sign in" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :credentials, in: :body, required: true, schema: {
        type: :object,
        required: %w[email password],
        properties: {
          email: { type: :string, format: :email },
          password: { type: :string, format: :password }
        }
      }

      response "200", "authenticated" do
        schema "$ref" => "#/components/schemas/LoginResponse"
        let(:credentials) { { email: "employee@example.com", password: "Password123!" } }
        run_test! if ARGV.include?("--dry-run")
      end

      response "401", "invalid credentials" do
        schema "$ref" => "#/components/schemas/Error"
        let(:credentials) { { email: "employee@example.com", password: "wrong" } }
      end
    end
  end

  path "/api/v1/auth/logout" do
    delete "Sign out" do
      tags "Authentication"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "204", "token revoked" do
        run_test! if ARGV.include?("--dry-run")
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end
  end

  path "/api/v1/me" do
    get "Get the current user" do
      tags "Authentication"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "current user" do
        schema "$ref" => "#/components/schemas/User"
        run_test! if ARGV.include?("--dry-run")
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end
  end

  path "/api/v2/categories" do
    get "List active categories" do
      tags "Categories"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "categories returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/Category" }
        run_test! if ARGV.include?("--dry-run")
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end
  end

  path "/api/v2/expenses" do
    get "List expenses" do
      tags "Expenses"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :page, in: :query, type: :integer, required: false, minimum: 1
      parameter name: :per_page, in: :query, type: :integer, required: false, minimum: 1, maximum: 50

      response "200", "expenses returned" do
        schema "$ref" => "#/components/schemas/ExpenseIndexResponse"
        let(:page) { 1 }
        let(:per_page) { 5 }
        run_test! if ARGV.include?("--dry-run")
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/Error"
      end

      response "403", "forbidden" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end

    post "Create a draft expense" do
      tags "Expenses"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :expense_request, in: :body, required: true, schema: {
        "$ref" => "#/components/schemas/ExpenseRequest"
      }

      response "201", "expense created" do
        schema "$ref" => "#/components/schemas/Expense"
        let(:expense_request) { { expense: { title: "Flight", amount: 250, category_id: 1, spent_date: Date.current } } }
        run_test! if ARGV.include?("--dry-run")
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ErrorList"
        let(:expense_request) { { expense: { title: "", amount: 0, category_id: 1, spent_date: Date.current } } }
      end
    end
  end

  path "/api/v2/expenses/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true

    get "Get an expense and its history" do
      tags "Expenses"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "expense returned" do
        schema "$ref" => "#/components/schemas/ExpenseDetail"
        let(:id) { expense.id }
        run_test! if ARGV.include?("--dry-run")
      end

      response "404", "expense not found" do
        schema "$ref" => "#/components/schemas/Error"
        let(:id) { 999_999 }
      end
    end

    patch "Update a draft expense" do
      tags "Expenses"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :expense_request, in: :body, required: true, schema: {
        "$ref" => "#/components/schemas/ExpenseRequest"
      }

      response "200", "expense updated" do
        schema "$ref" => "#/components/schemas/Expense"
        let(:id) { expense.id }
        let(:expense_request) { { expense: { title: "Updated flight" } } }
        run_test! if ARGV.include?("--dry-run")
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ErrorList"
        let(:id) { expense.id }
        run_test! if ARGV.include?("--dry-run")
        let(:expense_request) { { expense: { amount: 0 } } }
      end
    end

    delete "Delete a draft expense" do
      tags "Expenses"
      security [bearerAuth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "204", "expense deleted" do
        let(:id) { expense.id }
      end

      response "404", "expense not found" do
        schema "$ref" => "#/components/schemas/Error"
        let(:id) { 999_999 }
      end
    end
  end

  path "/api/v2/expenses/{id}/submit" do
    post "Submit a draft expense" do
      tags "Expenses"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true

      response "200", "expense submitted" do
        schema "$ref" => "#/components/schemas/Expense"
        let(:id) { expense.id }
        run_test! if ARGV.include?("--dry-run")
      end

      response "422", "expense cannot be submitted" do
        schema "$ref" => "#/components/schemas/ErrorList"
        let(:id) { expense.id }
      end
    end
  end
end

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

      response "200", "current user" do
        schema "$ref" => "#/components/schemas/User"
        run_test! if ARGV.include?("--dry-run")
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end
  end

  path "/api/v1/categories" do
    get "List active categories" do
      tags "Categories"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "categories returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/Category" }
        run_test! if ARGV.include?("--dry-run")
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end
  end

  path "/api/v1/expenses" do
    get "List expenses" do
      tags "Expenses"
      produces "application/json"
      security [bearerAuth: []]
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

  path "/api/v1/expenses/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true

    get "Get an expense and its history" do
      tags "Expenses"
      produces "application/json"
      security [bearerAuth: []]

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

      response "204", "expense deleted" do
        let(:id) { expense.id }
      end

      response "404", "expense not found" do
        schema "$ref" => "#/components/schemas/Error"
        let(:id) { 999_999 }
      end
    end
  end

  path "/api/v1/expenses/{id}/submit" do
    post "Submit a draft expense" do
      tags "Expenses"
      produces "application/json"
      security [bearerAuth: []]
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

  path "/api/v1/expenses/{id}/reopen" do
    post "Reopen a rejected expense" do
      tags "Expenses"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :id, in: :path, type: :integer, required: true

      response "200", "expense reopened" do
        schema "$ref" => "#/components/schemas/Expense"
        let(:id) { expense.id }
        run_test! if ARGV.include?("--dry-run")
      end
      response "422", "expense cannot be reopened" do
        schema "$ref" => "#/components/schemas/Error"
        let(:id) { expense.id }
      end
    end
  end

  path "/api/v1/notifications" do
    get "List unread notifications" do
      tags "Notifications"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "notifications returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/Notification" }
        run_test! if ARGV.include?("--dry-run")
      end
    end
  end

  path "/api/v1/admin/users" do
    get "List users" do
      tags "Admin - Users"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :search, in: :query, type: :string
      parameter name: :role, in: :query, type: :string, enum: %w[employee manager admin]
      parameter name: :sort, in: :query, type: :string, enum: %w[email role active created_at]
      parameter name: :direction, in: :query, type: :string, enum: %w[asc desc]
      parameter name: :page, in: :query, type: :integer, minimum: 1
      parameter name: :per_page, in: :query, type: :integer, minimum: 1, maximum: 50
      response "200", "users returned" do
        schema "$ref" => "#/components/schemas/UserIndexResponse"
        run_test! if ARGV.include?("--dry-run")
      end
    end

    post "Create a user" do
      tags "Admin - Users"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :user_request, in: :body, required: true, schema: { "$ref" => "#/components/schemas/UserRequest" }
      response "201", "user created" do
        schema "$ref" => "#/components/schemas/User"
        run_test! if ARGV.include?("--dry-run")
      end
      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ErrorList"
      end
    end
  end

  path "/api/v1/admin/users/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true

    patch "Update a user" do
      tags "Admin - Users"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :user_request, in: :body, required: true, schema: { "$ref" => "#/components/schemas/UserRequest" }
      response "200", "user updated" do
        schema "$ref" => "#/components/schemas/User"
        run_test! if ARGV.include?("--dry-run")
      end
      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ErrorList"
      end
    end
  end

  ["activate", "deactivate"].each do |action|
    path "/api/v1/admin/users/{id}/#{action}" do
      post "#{action.capitalize} a user" do
        tags "Admin - Users"
        produces "application/json"
        security [bearerAuth: []]
        parameter name: :id, in: :path, type: :integer, required: true
        response "200", "user status updated" do
          schema "$ref" => "#/components/schemas/User"
          run_test! if ARGV.include?("--dry-run")
        end
      end
    end
  end

  path "/api/v1/admin/expenses" do
    get "List non-draft expenses" do
      tags "Admin - Expenses"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :search, in: :query, type: :string
      parameter name: :state, in: :query, type: :string, enum: %w[submitted approved rejected reimbursed]
      parameter name: :category, in: :query, type: :integer
      parameter name: :from_date, in: :query, type: :string, format: :date
      parameter name: :to_date, in: :query, type: :string, format: :date
      parameter name: :page, in: :query, type: :integer, minimum: 1
      parameter name: :per_page, in: :query, type: :integer, minimum: 1, maximum: 50
      response "200", "expenses returned" do
        schema "$ref" => "#/components/schemas/ExpenseIndexResponse"
        run_test! if ARGV.include?("--dry-run")
      end
    end
  end

  path "/api/v1/admin/expenses/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true
    get "Get an admin expense" do
      tags "Admin - Expenses"
      produces "application/json"
      security [bearerAuth: []]
      response "200", "expense returned" do
        schema "$ref" => "#/components/schemas/ExpenseDetail"
        run_test! if ARGV.include?("--dry-run")
      end
      response "404", "expense not found" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end
  end

  ["approve", "reject", "reimburse"].each do |action|
    path "/api/v1/admin/expenses/{id}/#{action}" do
      post "#{action.capitalize} an expense" do
        tags "Admin - Expenses"
        consumes "application/json"
        produces "application/json"
        security [bearerAuth: []]
        parameter name: :id, in: :path, type: :integer, required: true
        parameter name: :comment, in: :body, required: false, schema: { type: :object, properties: { comment: { type: :string }, payment_reference: { type: :string } } }
        response "200", "expense action completed" do
          schema "$ref" => "#/components/schemas/Expense"
          run_test! if ARGV.include?("--dry-run")
        end
        response "404", "expense not found" do
          schema "$ref" => "#/components/schemas/Error"
        end
        response "422", "expense action rejected" do
          schema "$ref" => "#/components/schemas/Error"
        end
      end
    end
  end

  path "/api/v1/admin/categories" do
    get "List categories" do
      tags "Admin - Categories"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :sort, in: :query, type: :string, enum: %w[name auto_approve_limit active created_at]
      parameter name: :direction, in: :query, type: :string, enum: %w[asc desc]
      parameter name: :page, in: :query, type: :integer, minimum: 1
      parameter name: :per_page, in: :query, type: :integer, minimum: 1, maximum: 50
      response "200", "categories returned" do
        schema "$ref" => "#/components/schemas/CategoryIndexResponse"
        run_test! if ARGV.include?("--dry-run")
      end
    end
    post "Create a category" do
      tags "Admin - Categories"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :category_request, in: :body, required: true, schema: { "$ref" => "#/components/schemas/CategoryRequest" }
      response "201", "category created" do
        schema "$ref" => "#/components/schemas/Category"
        run_test! if ARGV.include?("--dry-run")
      end
      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ErrorList"
      end
    end
  end

  path "/api/v1/admin/categories/{id}" do
    patch "Update a category" do
      tags "Admin - Categories"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :category_request, in: :body, required: true, schema: { "$ref" => "#/components/schemas/CategoryRequest" }
      response "200", "category updated" do
        schema "$ref" => "#/components/schemas/Category"
        run_test! if ARGV.include?("--dry-run")
      end
    end
  end

  path "/api/v1/admin/teams" do
    get "List teams" do
      tags "Admin - Teams"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :page, in: :query, type: :integer, minimum: 1
      parameter name: :per_page, in: :query, type: :integer, minimum: 1, maximum: 50
      response "200", "teams returned" do
        schema "$ref" => "#/components/schemas/TeamIndexResponse"
        run_test! if ARGV.include?("--dry-run")
      end
    end
    post "Create a team" do
      tags "Admin - Teams"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :team_request, in: :body, required: true, schema: { "$ref" => "#/components/schemas/TeamRequest" }
      response "201", "team created" do
        schema "$ref" => "#/components/schemas/Team"
        run_test! if ARGV.include?("--dry-run")
      end
      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ErrorList"
      end
    end
  end

  path "/api/v1/admin/teams/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true
    patch "Update a team" do
      tags "Admin - Teams"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :team_request, in: :body, required: true, schema: { "$ref" => "#/components/schemas/TeamRequest" }
      response "200", "team updated" do
        schema "$ref" => "#/components/schemas/Team"
        run_test! if ARGV.include?("--dry-run")
      end
    end
    delete "Delete a team" do
      tags "Admin - Teams"
      security [bearerAuth: []]
      response "204", "team deleted" do
        run_test! if ARGV.include?("--dry-run")
      end
      response "422", "team cannot be deleted" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end
  end

  path "/api/v1/admin/report" do
    get "Generate an expense report" do
      tags "Admin - Reports"
      produces "application/json", "text/csv"
      security [bearerAuth: []]
      parameter name: :from, in: :query, type: :string, format: :date, required: true
      parameter name: :to, in: :query, type: :string, format: :date, required: true
      parameter name: :state, in: :query, type: :string, enum: %w[approved reimbursed]
      response "200", "report generated" do
        schema "$ref" => "#/components/schemas/Report"
        run_test! if ARGV.include?("--dry-run")
      end
      response "422", "invalid date range" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end
  end

  path "/api/v1/manager/expenses" do
    get "List manager expenses" do
      tags "Manager - Expenses"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :state, in: :query, type: :string, enum: %w[draft submitted approved rejected reimbursed]
      parameter name: :page, in: :query, type: :integer, minimum: 1
      parameter name: :per_page, in: :query, type: :integer, minimum: 1, maximum: 50
      response "200", "expenses returned" do
        schema "$ref" => "#/components/schemas/ExpenseIndexResponse"
        run_test! if ARGV.include?("--dry-run")
      end
    end
    post "Create a manager expense" do
      tags "Manager - Expenses"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :expense_request, in: :body, required: true, schema: { "$ref" => "#/components/schemas/ExpenseRequest" }
      response "201", "expense created" do
        schema "$ref" => "#/components/schemas/Expense"
        run_test! if ARGV.include?("--dry-run")
      end
    end
  end

  path "/api/v1/manager/expenses/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true
    get "Get a manager expense" do
      tags "Manager - Expenses"
      produces "application/json"
      security [bearerAuth: []]
      response "200", "expense returned" do
        schema "$ref" => "#/components/schemas/ExpenseDetail"
        run_test! if ARGV.include?("--dry-run")
      end
      response "404", "expense not found" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end
    patch "Update a manager expense" do
      tags "Manager - Expenses"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :expense_request, in: :body, required: true, schema: { "$ref" => "#/components/schemas/ExpenseRequest" }
      response "200", "expense updated" do
        schema "$ref" => "#/components/schemas/Expense"
        run_test! if ARGV.include?("--dry-run")
      end
    end
    delete "Delete a manager expense" do
      tags "Manager - Expenses"
      security [bearerAuth: []]
      response "204", "expense deleted" do
        run_test! if ARGV.include?("--dry-run")
      end
    end
  end

  path "/api/v1/manager/expenses/{id}/submit" do
    post "Submit a manager expense" do
      tags "Manager - Expenses"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :id, in: :path, type: :integer, required: true
      response "200", "expense submitted" do
        schema "$ref" => "#/components/schemas/Expense"
        run_test! if ARGV.include?("--dry-run")
      end
      response "422", "expense cannot be submitted" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end
  end

  path "/api/v1/manager/team_members" do
    get "List team members" do
      tags "Manager - Team Members"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :page, in: :query, type: :integer, minimum: 1
      parameter name: :per_page, in: :query, type: :integer, minimum: 1, maximum: 50
      response "200", "team members returned" do
        schema "$ref" => "#/components/schemas/UserIndexResponse"
        run_test! if ARGV.include?("--dry-run")
      end
    end
  end

  path "/api/v1/manager/reviews" do
    get "List team expense reviews" do
      tags "Manager - Reviews"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :state, in: :query, type: :string, enum: %w[submitted approved rejected reimbursed]
      parameter name: :page, in: :query, type: :integer, minimum: 1
      parameter name: :per_page, in: :query, type: :integer, minimum: 1, maximum: 50
      response "200", "reviews returned" do
        schema "$ref" => "#/components/schemas/ExpenseIndexResponse"
        run_test! if ARGV.include?("--dry-run")
      end
    end
  end

  path "/api/v1/manager/reviews/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true
    get "Get a team expense review" do
      tags "Manager - Reviews"
      produces "application/json"
      security [bearerAuth: []]
      response "200", "review returned" do
        schema "$ref" => "#/components/schemas/ExpenseDetail"
        run_test! if ARGV.include?("--dry-run")
      end
      response "404", "review not found" do
        schema "$ref" => "#/components/schemas/Error"
      end
    end
  end

  ["approve", "reject"].each do |action|
    path "/api/v1/manager/reviews/{id}/#{action}" do
      post "#{action.capitalize} a team expense" do
        tags "Manager - Reviews"
        consumes "application/json"
        produces "application/json"
        security [bearerAuth: []]
        parameter name: :id, in: :path, type: :integer, required: true
        parameter name: :review, in: :body, required: false, schema: { type: :object, properties: { comment: { type: :string } } }
        response "200", "review action completed" do
          schema "$ref" => "#/components/schemas/Expense"
          run_test! if ARGV.include?("--dry-run")
        end
        response "404", "review not found" do
          schema "$ref" => "#/components/schemas/Error"
        end
        response "422", "review action rejected" do
          schema "$ref" => "#/components/schemas/Error"
        end
      end
    end
  end
end

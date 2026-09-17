# frozen_string_literal: true

require 'rails_helper'
require 'rswag/specs'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},

      
      security: [
        { bearerAuth: [] }
      ],

      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        },
        schemas: {
          Error: {
            type: :object,
            properties: { error: { type: :string } }
          },
          ErrorList: {
            type: :object,
            properties: { errors: { type: :array, items: { type: :string } } }
          },
          User: {
            type: :object,
            properties: {
              id: { type: :integer },
              email: { type: :string, format: :email },
              role: { type: :string, enum: %w[employee manager admin] },
              active: { type: :boolean },
              team_id: { type: :integer, nullable: true },
              team_name: { type: :string, nullable: true }
            }
          },
          LoginResponse: {
            type: :object,
            properties: {
              token: { type: :string },
              user: { '$ref' => '#/components/schemas/User' }
            }
          },
          Category: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              auto_approve_limit: { type: :number, format: :double }
            }
          },
          ExpenseRequest: {
            type: :object,
            required: [:expense],
            properties: {
              expense: {
                type: :object,
                required: %i[title amount category_id spent_date],
                properties: {
                  title: { type: :string },
                  description: { type: :string, nullable: true },
                  amount: { type: :number, format: :double, exclusiveMinimum: 0, maximum: 100_000 },
                  category_id: { type: :integer },
                  spent_date: { type: :string, format: :date }
                }
              }
            }
          },
          Expense: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string, nullable: true },
              amount: { type: :number, format: :double },
              category_id: { type: :integer },
              category_name: { type: :string },
              payment_reference: { type: :string, nullable: true },
              spent_date: { type: :string, format: :date },
              state: { type: :string, enum: %w[draft submitted approved rejected reimbursed] },
              approval_stage: { type: :string, nullable: true },
              user_id: { type: :integer },
              user_email: { type: :string, format: :email },
              user_role: { type: :string, enum: %w[employee manager admin] },
              created_at: { type: :string, format: :'date-time' },
              updated_at: { type: :string, format: :'date-time' }
            }
          },
          History: {
            type: :object,
            properties: {
              id: { type: :integer },
              prev_state: { type: :integer, enum: [0, 1, 2, 3, 4] },
              next_state: { type: :integer, enum: [0, 1, 2, 3, 4] },
              comment: { type: :string, nullable: true },
              changed_by: { type: :string, nullable: true },
              created_at: { type: :string, format: :'date-time' }
            }
          },
          ExpenseDetail: {
            allOf: [
              { '$ref' => '#/components/schemas/Expense' },
              {
                type: :object,
                properties: {
                  history: { type: :array, items: { '$ref' => '#/components/schemas/History' } }
                }
              }
            ]
          },
          ExpenseIndexResponse: {
            type: :object,
            properties: {
              expenses: { type: :array, items: { '$ref' => '#/components/schemas/Expense' } },
              pagination: {
                type: :object,
                properties: {
                  page: { type: :integer },
                  per_page: { type: :integer },
                  total_count: { type: :integer },
                  total_pages: { type: :integer }
                }
              }
            }
          }, # 👈 this closing brace was missing
          UserRequest: {
            type: :object,
            required: [:user],
            properties: {
              user: {
                type: :object,
                required: %i[email role],
                properties: {
                  email: { type: :string, format: :email },
                  password: { type: :string, format: :password },
                  role: { type: :string, enum: %w[employee manager admin] },
                  team_id: { type: :integer, nullable: true }
                }
              }
            }
          },
          CategoryRequest: {
            type: :object,
            required: [:category],
            properties: {
              category: {
                type: :object,
                required: [:name],
                properties: {
                  name: { type: :string },
                  auto_approve_limit: { type: :number, format: :double },
                  active: { type: :boolean }
                }
              }
            }
          },
          Team: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              manager_id: { type: :integer },
              manager_email: { type: :string, format: :email, nullable: true }
            }
          },
          TeamRequest: {
            type: :object,
            required: [:team],
            properties: {
              team: {
                type: :object,
                required: %i[name manager_id],
                properties: { name: { type: :string }, manager_id: { type: :integer } }
              }
            }
          },
          Notification: {
            type: :object,
            properties: {
              id: { type: :integer },
              content: { type: :string },
              created_at: { type: :string, format: :'date-time' }
            }
          },
          Report: {
            type: :object,
            properties: {
              generated_at: { type: :string, format: :'date-time' },
              filters: { type: :object },
              rows: { type: :array, items: { type: :object } },
              summary: { type: :object }
            }
          },
          Pagination: {
            type: :object,
            properties: {
              page: { type: :integer },
              per_page: { type: :integer },
              total_count: { type: :integer },
              total_pages: { type: :integer }
            }
          },
          UserIndexResponse: {
            type: :object,
            properties: {
              users: { type: :array, items: { '$ref' => '#/components/schemas/User' } },
              pagination: { '$ref' => '#/components/schemas/Pagination' }
            }
          },
          CategoryIndexResponse: {
            type: :object,
            properties: {
              categories: { type: :array, items: { '$ref' => '#/components/schemas/Category' } },
              pagination: { '$ref' => '#/components/schemas/Pagination' }
            }
          },
          TeamIndexResponse: {
            type: :object,
            properties: {
              teams: { type: :array, items: { '$ref' => '#/components/schemas/Team' } },
              pagination: { '$ref' => '#/components/schemas/Pagination' }
            }
          }
        }
      },
      servers: [
        { url: 'http://localhost:3000' }
      ]
    }
  }

  config.openapi_format = :yaml
end
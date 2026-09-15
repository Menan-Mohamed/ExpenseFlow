# frozen_string_literal: true

require 'rails_helper'
require 'rswag/specs'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
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
              team_id: { type: :integer, nullable: true }
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
              spent_date: { type: :string, format: :date },
              state: { type: :string, enum: %w[draft submitted approved rejected reimbursed] },
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
          }
        }
      },
      servers: [
        {
          url: 'http://localhost:3000'
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end

# ExpenseFlow Backend

## Setup

```bash
bundle install
bin/rails db:prepare
```

The application expects PostgreSQL. Set `DB_HOST`, `DB_USERNAME`, and
`DB_PASSWORD` when the database is not running with the local defaults.

Set `EXPENSE_TWO_LEVEL_APPROVAL_THRESHOLD` to configure the amount above which
employee expenses require manager approval followed by admin approval. It
defaults to `1000`.

## Tests

```bash
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
```

The request and model specs live under `spec/` and cover authentication,
authorization, expense CRUD, submission history, pagination, and validations.

## API documentation

Swagger UI is available at `http://localhost:3000/api-docs` when the Rails
server is running:

```bash
bin/rails server
```

Generate the OpenAPI document from rswag specs with:

```bash
bundle exec rake rswag:specs:swaggerize
```

The generated document is written to [`swagger/v1/swagger.yaml`](swagger/v1/swagger.yaml).
Add or update specs that require `swagger_helper` to keep the generated API
documentation synchronized with executable request tests.
# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

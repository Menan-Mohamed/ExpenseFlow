# ExpenseFlow

A team expense reimbursement platform — employees submit expenses, managers review their team's submissions, and admins (finance) manage users/teams/categories and reimburse approved expenses.

**Stack:** Ruby on Rails 7.1 (API mode) · PostgreSQL 16 · React (Vite)

---

## Setup and run instructions

The whole stack starts with a single command.

```bash
docker compose up --build
```

This will:
- Build the `backend` (Rails API) and `frontend` (React/Vite) images
- Start a PostgreSQL 16 container
- Prepare the database (create + migrate) and seed it with demo data automatically on container start

Once running:
- Frontend: [http://localhost:5173](http://localhost:5173)
- Backend API: [http://localhost:3000](http://localhost:3000) (health check at `/up`)
- Postgres: exposed on `localhost:5432` if you want to inspect it with a GUI (e.g. pgAdmin) using the credentials in `docker-compose.yml`


Requires Ruby 3.3.5, Node 20+, and a local PostgreSQL instance (see `config/database.yml` for expected connection settings, overridable via `DB_HOST` / `DB_USERNAME` / `DB_PASSWORD` env vars).

---

## Environment Variables

| Variable | Used by | Default | Description |
|---|---|---|---|
| `RAILS_ENV` | backend | `development` | Rails environment; the Docker setup runs in `development` (see Assumptions below) |
| `DB_HOST` | backend | `localhost` | Postgres host — set to `db` automatically inside Docker Compose |
| `DB_USERNAME` | backend | `expenseflow` | Postgres role used by the Rails app |
| `DB_PASSWORD` | backend | `expenseflow` | Password for the above role |
| `TWO_LEVEL_APPROVAL_THRESHOLD` | backend | `1000` | Amount above which an expense requires manager approval *then* admin approval (bonus feature) |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | db (Docker) | `expenseflow` / `expenseflow` / `expenseflow_development` | Initializes the Postgres container on first boot |

All of these are already set with working defaults in `docker-compose.yml`, so `docker compose up --build` works out of the box with no `.env` file required. Override any of them by exporting the variable before running compose, e.g.:

```bash
TWO_LEVEL_APPROVAL_THRESHOLD=500 docker compose up --build
```

---

## CI/CD

The project uses **GitHub Actions** for continuous integration. The workflow (`.github/workflows/backend-tests.yml`) runs automatically on every pull request that touches `backend/**`, This gives report of pass tests and coverge.

---

## API Documentation

Once the backend is running, API documentation is available at:

* **Swagger UI** — [http://localhost:3000/api-docs](http://localhost:3000/api-docs)

---

## Authentication approach

Authentication is implemented from scratch , using **JWTs with a denylist for logout**.

- **Login** (`POST /api/v1/auth/login`) verifies email + password (via `bcrypt`/`has_secure_password`) and issues a signed JWT containing `user_id`, a unique `jti` (token ID), and a short expiry (`exp`).
- **Every authenticated request** decodes the token, checks it hasn't expired, checks its `jti` isn't in the `jwt_denylists` table, and confirms `active: true` **on every request** from database.
- **Logout** (`DELETE /api/v1/auth/logout`) inserts the current token's `jti` into `jwt_denylists`, so that specific token is rejected on all future requests even though it hasn't naturally expired yet.
- **`GET /api/v1/me`** returns the current authenticated user's profile.

There is no public sign-up. Users are created only by an admin (`POST /api/v1/users`) or the seed script.

---

## Demo credentials

All passwords: `1234`

| Role | Email | Notes |
|---|---|---|
| Admin | `admin1@expenseflow.com` | Reviews managers'/admins' expenses; reimburses |
| Admin | `admin2@expenseflow.com` | Used to demo "an admin's expense is reviewed by a *different* admin" |
| Manager | `manager@expenseflow.com` | Manages the **Engineering** team |
| Manager | `manager2@expenseflow.com` | Manages the **Sales** team — used to prove managers can't see/act on the other team's expenses |
| Employee | `employee@expenseflow.com` | Member of Engineering |
| Employee | `employee2@expenseflow.com` | Member of Sales |
| Employee (deactivated) | `deactivated@expenseflow.com` | `active: false` — use to confirm login is blocked and an existing token is rejected immediately |

The seed script (`db/seeds.rb`) creates expenses covering every state (`draft`, `submitted`, `approved`, `rejected`, `reimbursed`), an auto-approved expense, a full reject → reopen → resubmit → approve cycle, and a two-level (manager then admin) approval example.

---

## Overview of approach

- **Roles** are a single `role` enum on `User` (`employee` / `manager` / `admin`) rather than separate tables — this keeps auth, notifications, and expense ownership uniform across all three roles instead of needing parallel code paths per role.
- **State transitions** (`submit!`, `approve!`, `reject!`, `reopen!`, `reimburse!`) live in a single `ExpenseTransition` service object rather than directly on the `Expense` model or in the controller. Each method: validates the transition is legal for the expense's current state, checks the actor is authorized to perform it, writes a `History` row, updates the expense, and notifies the owner — all inside `expense.with_lock` to guard against concurrent double-submission/double-review.
- **Authorization** for "who can review this expense" is centralized in `Expense#eligible_reviewer?`, used by both `approve!` and `reject!`, so the review-eligibility rule (employee → their manager; manager/admin → an admin, never themselves) has one source of truth rather than being duplicated per action.
- **Auto-approval** is checked at `submit!` time by comparing the amount to the category's `auto_approve_limit`; the resulting history row records the change as made by `nil` (rendered as "system").
- **Two-level approval (bonus)** is modeled with an `approval_stage` column (`not_applicable` / `awaiting_manager` / `awaiting_admin`) rather than new top-level `Expense` states. The manager's sign-off is recorded as a `submitted → submitted` history row noting stage 1 of 2, keeping the externally visible state machine unchanged.


---

## Assumptions

- **Team creation requires an existing user with the `manager` role**, referenced by `manager_id`. 

---

## Known limitations and what I'd do with more time

- **Notifications are polling-based, not real-time (no WebSockets).**

- **The JWT denylist table (`jwt_denylists`) is never pruned.**(not deleted periodically)

- **Team update/delete has unhandled edge cases.** Specifically: what should happen to a team's employees if the team is deleted and what should happen if an admin changes a team's `manager_id` to a different manager.

- **No rate limiting on `/api/v1/auth/login`.** A brute-force login attempt isn't currently throttled. With more time, I'd add `rack-attack` to rate-limit repeated failed login attempts per IP/email.

---

## Demo Video Link

* https://drive.google.com/file/d/1o6J7_JMd680Y-DavihF5uXORk4AsF0ry/view?usp=sharing

### slides:
* https://drive.google.com/drive/folders/1NVh9KQ9sd4FRdjr7p1Vqcw1uqd0I0F-y?usp=sharing


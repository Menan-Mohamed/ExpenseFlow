# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_09_15_070000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.decimal "auto_approve_limit"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_categories_on_lower_name", unique: true
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.string "title"
    t.text "description"
    t.decimal "amount"
    t.date "spent_date"
    t.integer "state", default: 0
    t.string "payment_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "histories", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.bigint "changer_id"
    t.integer "prev_state"
    t.integer "next_state"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["changer_id"], name: "index_histories_on_changer_id"
    t.index ["expense_id"], name: "index_histories_on_expense_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "content"
    t.boolean "is_read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "manager_id"
    t.index ["manager_id"], name: "index_teams_on_manager_id", unique: true
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.integer "role"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "team_id"
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "users"
  add_foreign_key "histories", "expenses"
  add_foreign_key "histories", "users", column: "changer_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "teams", "users", column: "manager_id"
  add_foreign_key "users", "teams"
end

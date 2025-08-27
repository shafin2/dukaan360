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

ActiveRecord::Schema[8.0].define(version: 2025_08_24_102455) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "bill_items", force: :cascade do |t|
    t.bigint "bill_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.decimal "unit_price"
    t.decimal "total_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_bill_items_on_bill_id"
    t.index ["product_id"], name: "index_bill_items_on_product_id"
  end

  create_table "bills", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "user_id", null: false
    t.bigint "shop_id", null: false
    t.string "bill_number"
    t.decimal "total_amount"
    t.string "status"
    t.datetime "bill_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bill_type"
    t.date "due_date"
    t.index ["customer_id"], name: "index_bills_on_customer_id"
    t.index ["shop_id"], name: "index_bills_on_shop_id"
    t.index ["user_id"], name: "index_bills_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.text "address"
    t.decimal "total_credit"
    t.decimal "total_paid"
    t.bigint "user_id", null: false
    t.bigint "shop_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_customers_on_shop_id"
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "bill_id", null: false
    t.bigint "customer_id", null: false
    t.bigint "user_id", null: false
    t.decimal "amount"
    t.datetime "payment_date"
    t.string "payment_method"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_payments_on_bill_id"
    t.index ["customer_id"], name: "index_payments_on_customer_id"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "category"
    t.decimal "buying_price", precision: 10, scale: 2, null: false
    t.decimal "selling_price", precision: 10, scale: 2, null: false
    t.integer "quantity", default: 0, null: false
    t.date "expiry_date"
    t.bigint "shop_id", null: false
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "sku"
    t.text "image_url"
    t.index ["category"], name: "index_products_on_category"
    t.index ["created_by_id"], name: "index_products_on_created_by_id"
    t.index ["expiry_date"], name: "index_products_on_expiry_date"
    t.index ["name"], name: "index_products_on_name"
    t.index ["shop_id", "category"], name: "index_products_on_shop_id_and_category"
    t.index ["shop_id"], name: "index_products_on_shop_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "user_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.datetime "sale_date", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "bill_id"
    t.index ["bill_id"], name: "index_sales_on_bill_id"
    t.index ["product_id", "sale_date"], name: "index_sales_on_product_id_and_sale_date"
    t.index ["product_id"], name: "index_sales_on_product_id"
    t.index ["sale_date"], name: "index_sales_on_sale_date"
    t.index ["user_id", "sale_date"], name: "index_sales_on_user_id_and_sale_date"
    t.index ["user_id"], name: "index_sales_on_user_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.text "address"
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_shops_on_name"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "role", default: 1, null: false
    t.bigint "shop_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["shop_id", "role"], name: "index_users_on_shop_id_and_role"
    t.index ["shop_id"], name: "index_users_on_shop_id"
  end

  add_foreign_key "bill_items", "bills"
  add_foreign_key "bill_items", "products"
  add_foreign_key "bills", "customers"
  add_foreign_key "bills", "shops"
  add_foreign_key "bills", "users"
  add_foreign_key "customers", "shops"
  add_foreign_key "customers", "users"
  add_foreign_key "payments", "bills"
  add_foreign_key "payments", "customers"
  add_foreign_key "payments", "users"
  add_foreign_key "products", "shops"
  add_foreign_key "products", "users", column: "created_by_id"
  add_foreign_key "sales", "bills"
  add_foreign_key "sales", "products"
  add_foreign_key "sales", "users"
  add_foreign_key "users", "shops"
end

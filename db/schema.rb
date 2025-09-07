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

ActiveRecord::Schema[8.0].define(version: 2025_08_31_123355) do
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

  create_table "businesses", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "business_type"
    t.string "contact_email"
    t.string "contact_phone"
    t.text "address"
    t.string "logo_url"
    t.string "primary_color", default: "#3B82F6"
    t.string "secondary_color", default: "#1F2937"
    t.string "website_url"
    t.jsonb "settings", default: {}
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_businesses_on_active"
    t.index ["name"], name: "index_businesses_on_name", unique: true
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

  create_table "permissions", force: :cascade do |t|
    t.string "name", null: false
    t.string "resource", null: false
    t.string "action", null: false
    t.text "description"
    t.string "category", default: "general"
    t.boolean "system_permission", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_permissions_on_category"
    t.index ["name"], name: "index_permissions_on_name", unique: true
    t.index ["resource", "action"], name: "index_permissions_on_resource_and_action", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "category"
    t.decimal "buying_price", precision: 10, scale: 2, null: false
    t.decimal "selling_price", precision: 10, scale: 2, null: false
    t.date "expiry_date"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "sku"
    t.text "image_url"
    t.bigint "business_id", default: 1, null: false
    t.integer "min_stock_level", default: 10
    t.integer "max_stock_level", default: 100
    t.integer "reorder_point", default: 20
    t.string "unit", default: "piece", null: false
    t.index ["business_id", "category"], name: "index_products_on_business_id_and_category"
    t.index ["business_id"], name: "index_products_on_business_id"
    t.index ["category"], name: "index_products_on_category"
    t.index ["created_by_id"], name: "index_products_on_created_by_id"
    t.index ["expiry_date"], name: "index_products_on_expiry_date"
    t.index ["name"], name: "index_products_on_name"
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

  create_table "shop_inventories", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "product_id", null: false
    t.bigint "business_id", null: false
    t.integer "quantity", default: 0, null: false
    t.integer "min_stock_level", default: 10, null: false
    t.integer "max_stock_level", default: 100, null: false
    t.integer "reorder_point", default: 20, null: false
    t.datetime "last_restocked_at"
    t.text "restock_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_shop_inventories_on_business_id"
    t.index ["product_id"], name: "index_shop_inventories_on_product_id"
    t.index ["quantity", "reorder_point"], name: "index_shop_inventories_stock_levels"
    t.index ["quantity"], name: "index_shop_inventories_on_quantity"
    t.index ["shop_id", "product_id"], name: "index_shop_inventories_unique_shop_product", unique: true
    t.index ["shop_id"], name: "index_shop_inventories_on_shop_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.text "address"
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "business_id", null: false
    t.index ["business_id", "name"], name: "index_shops_on_business_id_and_name", unique: true
    t.index ["business_id"], name: "index_shops_on_business_id"
  end

  create_table "stock_transfers", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "from_shop_id", null: false
    t.bigint "to_shop_id", null: false
    t.bigint "initiated_by_id", null: false
    t.bigint "approved_by_id"
    t.bigint "business_id", null: false
    t.integer "quantity", null: false
    t.text "reason", null: false
    t.integer "status", default: 0, null: false
    t.datetime "approved_at"
    t.datetime "completed_at"
    t.datetime "cancelled_at"
    t.text "cancellation_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_stock_transfers_on_approved_by_id"
    t.index ["business_id"], name: "index_stock_transfers_on_business_id"
    t.index ["created_at"], name: "index_stock_transfers_on_created_at"
    t.index ["from_shop_id", "status"], name: "index_stock_transfers_on_from_shop_id_and_status"
    t.index ["from_shop_id"], name: "index_stock_transfers_on_from_shop_id"
    t.index ["initiated_by_id"], name: "index_stock_transfers_on_initiated_by_id"
    t.index ["product_id"], name: "index_stock_transfers_on_product_id"
    t.index ["status"], name: "index_stock_transfers_on_status"
    t.index ["to_shop_id", "status"], name: "index_stock_transfers_on_to_shop_id_and_status"
    t.index ["to_shop_id"], name: "index_stock_transfers_on_to_shop_id"
  end

  create_table "user_permissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "permission_id", null: false
    t.bigint "shop_id"
    t.boolean "granted", default: true
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["granted"], name: "index_user_permissions_on_granted"
    t.index ["permission_id"], name: "index_user_permissions_on_permission_id"
    t.index ["shop_id"], name: "index_user_permissions_on_shop_id"
    t.index ["user_id", "permission_id", "shop_id"], name: "index_user_permissions_unique", unique: true
    t.index ["user_id"], name: "index_user_permissions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "role", default: 1, null: false
    t.bigint "shop_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "business_id"
    t.index ["business_id"], name: "index_users_on_business_id"
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
  add_foreign_key "products", "businesses"
  add_foreign_key "products", "users", column: "created_by_id"
  add_foreign_key "sales", "bills"
  add_foreign_key "sales", "products"
  add_foreign_key "sales", "users"
  add_foreign_key "shop_inventories", "businesses"
  add_foreign_key "shop_inventories", "products"
  add_foreign_key "shop_inventories", "shops"
  add_foreign_key "shops", "businesses"
  add_foreign_key "stock_transfers", "businesses"
  add_foreign_key "stock_transfers", "products"
  add_foreign_key "stock_transfers", "shops", column: "from_shop_id"
  add_foreign_key "stock_transfers", "shops", column: "to_shop_id"
  add_foreign_key "stock_transfers", "users", column: "approved_by_id"
  add_foreign_key "stock_transfers", "users", column: "initiated_by_id"
  add_foreign_key "user_permissions", "permissions"
  add_foreign_key "user_permissions", "shops"
  add_foreign_key "user_permissions", "users"
  add_foreign_key "users", "businesses"
  add_foreign_key "users", "shops"
end

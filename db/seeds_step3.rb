# Updated seed file for Step 3: Business-wide inventory with shop-specific stock allocation

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create Super Admin User for ActiveAdmin
admin_user = AdminUser.find_or_create_by!(email: 'superadmin@dukaan360.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
end

puts "✅ Super Admin User created: #{admin_user.email}"

# Create Sample Businesses
business1 = Business.find_or_create_by!(name: 'Emaan Traders') do |business|
  business.description = 'Premium wholesale trading company specializing in food products'
  business.business_type = 'Wholesale'
  business.contact_email = 'info@emaantraders.com'
  business.contact_phone = '+92-321-1234567'
  business.address = 'Block A, Johar Town, Lahore, Pakistan'
  business.logo_url = 'https://placehold.co/200x100/3B82F6/FFFFFF?text=Emaan+Traders'
  business.primary_color = '#3B82F6'
  business.secondary_color = '#1F2937'
  business.website_url = 'https://emaantraders.com'
  business.active = true
end

business2 = Business.find_or_create_by!(name: 'Shah Electronics') do |business|
  business.description = 'Leading electronics retailer and distributor'
  business.business_type = 'Electronics'
  business.contact_email = 'contact@shahelectronics.com'
  business.contact_phone = '+92-333-9876543'
  business.address = 'Electronics Market, Karachi, Pakistan'
  business.logo_url = 'https://placehold.co/200x100/3B82F6/FFFFFF?text=Shah+Electronics'
  business.primary_color = '#EF4444'
  business.secondary_color = '#991B1B'
  business.website_url = 'https://shahelectronics.com'
  business.active = true
end

puts "✅ Businesses created: #{Business.count} businesses"

# Create Sample Shops for Business 1 (Emaan Traders)
shop1 = Shop.find_or_create_by!(name: 'Main Warehouse', business: business1) do |shop|
  shop.address = 'Warehouse #1, Industrial Area, Lahore'
  shop.settings = {
    expiry_alert_days: 30,
    red_alert_days: 7,
    yellow_alert_days: 15
  }
end

shop2 = Shop.find_or_create_by!(name: 'Retail Outlet', business: business1) do |shop|
  shop.address = 'Shop #123, Main Market, Lahore'
  shop.settings = {
    expiry_alert_days: 45,
    red_alert_days: 10,
    yellow_alert_days: 20
  }
end

# Create Sample Shops for Business 2 (Shah Electronics)
shop3 = Shop.find_or_create_by!(name: 'Electronics Hub', business: business2) do |shop|
  shop.address = 'Shop #456, Electronics Market, Karachi'
  shop.settings = {
    expiry_alert_days: 60,
    red_alert_days: 15,
    yellow_alert_days: 30
  }
end

puts "✅ Shops created: #{Shop.count} shops"

# Create Super Admin User
super_admin = User.find_or_create_by!(email: 'admin@dukaan360.com') do |user|
  user.name = 'System Administrator'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = :super_admin
  # Super admin doesn't belong to any specific business or shop
end

# Create Business Admin for Business 1 (Emaan Traders)
business_admin1 = User.find_or_create_by!(email: 'owner@emaantraders.com') do |user|
  user.name = 'Muhammad Emaan'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.business = business1
  user.role = :business_admin
  # Business admin can manage all shops, so no specific shop assignment
end

# Create Workers for Emaan Traders shops
worker1 = User.find_or_create_by!(email: 'ali@emaantraders.com') do |user|
  user.name = 'Ali Hassan'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.business = business1
  user.shop = shop1  # Assigned to Main Warehouse
  user.role = :worker
end

worker2 = User.find_or_create_by!(email: 'fatima@emaantraders.com') do |user|
  user.name = 'Fatima Khan'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.business = business1
  user.shop = shop2  # Assigned to Retail Outlet
  user.role = :worker
end

# Create Business Admin for Business 2 (Shah Electronics)
business_admin2 = User.find_or_create_by!(email: 'owner@shahelectronics.com') do |user|
  user.name = 'Ahmed Shah'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.business = business2
  user.role = :business_admin
end

# Create Worker for Shah Electronics
worker3 = User.find_or_create_by!(email: 'hassan@shahelectronics.com') do |user|
  user.name = 'Hassan Ali'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.business = business2
  user.shop = shop3
  user.role = :worker
end

puts "✅ Users created: #{User.count} users"

# Create Sample Products for Emaan Traders (Business-wide products)
food_products_data = [
  { 
    name: 'Basmati Rice Premium', 
    category: 'Grains', 
    buying_price: 150, 
    selling_price: 180, 
    description: 'Premium quality basmati rice', 
    sku: 'EM-RICE-001',
    unit: 'kg',
    expiry_days: 90
  },
  { 
    name: 'Cooking Oil 1L', 
    category: 'Oil', 
    buying_price: 300, 
    selling_price: 350, 
    description: 'Pure cooking oil', 
    sku: 'EM-OIL-001',
    unit: 'bottle',
    expiry_days: 180
  },
  { 
    name: 'Wheat Flour 10kg', 
    category: 'Flour', 
    buying_price: 800, 
    selling_price: 950, 
    description: 'Fine wheat flour', 
    sku: 'EM-FLOUR-001',
    unit: 'bag',
    expiry_days: 120
  },
  { 
    name: 'White Sugar 1kg', 
    category: 'Sweeteners', 
    buying_price: 120, 
    selling_price: 140, 
    description: 'Refined white sugar', 
    sku: 'EM-SUGAR-001',
    unit: 'kg',
    expiry_days: 365
  },
  { 
    name: 'Red Lentils 1kg', 
    category: 'Grains', 
    buying_price: 200, 
    selling_price: 250, 
    description: 'Premium red lentils', 
    sku: 'EM-LENTIL-001',
    unit: 'kg',
    expiry_days: 150
  },
  { 
    name: 'Green Tea 500g', 
    category: 'Beverages', 
    buying_price: 400, 
    selling_price: 480, 
    description: 'Premium green tea', 
    sku: 'EM-TEA-001',
    unit: 'pack',
    expiry_days: 240
  }
]

food_products_data.each do |product_data|
  product = Product.find_or_create_by!(name: product_data[:name], business: business1) do |p|
    p.category = product_data[:category]
    p.buying_price = product_data[:buying_price]
    p.selling_price = product_data[:selling_price]
    p.description = product_data[:description]
    p.sku = product_data[:sku]
    p.unit = product_data[:unit]
    p.expiry_date = Date.current + product_data[:expiry_days].days
    p.min_stock_level = 20
    p.max_stock_level = 500
    p.reorder_point = 50
    p.created_by_id = business_admin1.id
  end
  
  # Create shop inventory for each shop in the business
  # Main Warehouse gets 70% of stock, Retail Outlet gets 30%
  warehouse_qty = [300, 150, 80, 200, 100, 80][food_products_data.index(product_data)]
  retail_qty = [100, 50, 20, 100, 40, 20][food_products_data.index(product_data)]
  
  ShopInventory.find_or_create_by!(shop: shop1, product: product, business: business1) do |inventory|
    inventory.quantity = warehouse_qty
    inventory.min_stock_level = 50
    inventory.max_stock_level = 400
    inventory.reorder_point = 80
  end
  
  ShopInventory.find_or_create_by!(shop: shop2, product: product, business: business1) do |inventory|
    inventory.quantity = retail_qty
    inventory.min_stock_level = 20
    inventory.max_stock_level = 150
    inventory.reorder_point = 30
  end
end

# Create Sample Products for Shah Electronics (Business-wide products)
electronics_products_data = [
  { 
    name: 'LED TV 32 inch', 
    category: 'Television', 
    buying_price: 25000, 
    selling_price: 30000, 
    description: 'HD LED Television', 
    sku: 'SE-TV-001',
    unit: 'piece'
  },
  { 
    name: 'Mobile Phone Samsung', 
    category: 'Mobile', 
    buying_price: 35000, 
    selling_price: 42000, 
    description: 'Samsung Galaxy smartphone', 
    sku: 'SE-MOB-001',
    unit: 'piece'
  },
  { 
    name: 'Refrigerator 12 Cu ft', 
    category: 'Appliances', 
    buying_price: 45000, 
    selling_price: 55000, 
    description: 'Energy efficient refrigerator', 
    sku: 'SE-REF-001',
    unit: 'piece'
  },
  { 
    name: 'Washing Machine 7kg', 
    category: 'Appliances', 
    buying_price: 40000, 
    selling_price: 48000, 
    description: 'Automatic washing machine', 
    sku: 'SE-WM-001',
    unit: 'piece'
  },
  { 
    name: 'Air Conditioner 1.5 Ton', 
    category: 'Appliances', 
    buying_price: 50000, 
    selling_price: 60000, 
    description: 'Energy efficient AC', 
    sku: 'SE-AC-001',
    unit: 'piece'
  },
  { 
    name: 'Laptop HP Core i5', 
    category: 'Computers', 
    buying_price: 65000, 
    selling_price: 75000, 
    description: 'HP laptop with Core i5', 
    sku: 'SE-LAP-001',
    unit: 'piece'
  }
]

electronics_products_data.each do |product_data|
  product = Product.find_or_create_by!(name: product_data[:name], business: business2) do |p|
    p.category = product_data[:category]
    p.buying_price = product_data[:buying_price]
    p.selling_price = product_data[:selling_price]
    p.description = product_data[:description]
    p.sku = product_data[:sku]
    p.unit = product_data[:unit]
    # Electronics don't have expiry dates
    p.min_stock_level = 5
    p.max_stock_level = 50
    p.reorder_point = 10
    p.created_by_id = business_admin2.id
  end
  
  # Create shop inventory for electronics hub
  initial_qty = [15, 25, 8, 5, 12, 10][electronics_products_data.index(product_data)]
  
  ShopInventory.find_or_create_by!(shop: shop3, product: product, business: business2) do |inventory|
    inventory.quantity = initial_qty
    inventory.min_stock_level = 3
    inventory.max_stock_level = 30
    inventory.reorder_point = 5
  end
end

puts "✅ Products created: #{Product.count} products"
puts "✅ Shop inventories created: #{ShopInventory.count} inventory records"

# Create some sample stock transfers to demonstrate the system
puts "\n📦 Creating sample stock transfers..."

# Transfer some rice from warehouse to retail outlet
rice_product = Product.find_by(name: 'Basmati Rice Premium', business: business1)
if rice_product
  transfer1 = StockTransfer.new(
    product: rice_product,
    from_shop: shop1,
    to_shop: shop2,
    quantity: 50,
    reason: "Retail outlet running low on rice stock, transferring from main warehouse",
    initiated_by: worker1,
    approved_by: business_admin1,
    business: business1,
    approved_at: 2.days.ago,
    completed_at: 1.day.ago
  )
  transfer1.status = :completed  # Set status after initialization
  transfer1.save!(validate: false)  # Skip validations for seed data
  puts "  ✅ Rice transfer completed: #{transfer1.quantity} kg"
end

# Pending transfer for cooking oil
oil_product = Product.find_by(name: 'Cooking Oil 1L', business: business1)
if oil_product
  transfer2 = StockTransfer.new(
    product: oil_product,
    from_shop: shop1,
    to_shop: shop2,
    quantity: 20,
    reason: "Need more cooking oil for upcoming festival season sales",
    initiated_by: worker2,
    business: business1
  )
  transfer2.status = :pending
  transfer2.save!(validate: false)  # Skip validations for seed data
  puts "  ⏳ Oil transfer pending approval: #{transfer2.quantity} bottles"
end

puts "✅ Stock transfers created: #{StockTransfer.count} transfers"

# Assign sample permissions to workers
puts "\n🔐 Assigning sample permissions to workers..."

# Basic permissions for all workers
basic_worker_permissions = ['view_dashboard', 'view_products', 'view_customers', 'create_sales', 'view_sales']

# Ali (Main Warehouse) - More inventory permissions
warehouse_permissions = basic_worker_permissions + ['create_products', 'edit_products', 'manage_inventory', 'view_buying_price']
warehouse_permissions.each do |permission_name|
  worker1.grant_permission(permission_name, shop1)
end

# Fatima (Retail Outlet) - More customer and billing permissions  
retail_permissions = basic_worker_permissions + ['create_customers', 'edit_customers', 'create_bills', 'view_bills', 'create_payments']
retail_permissions.each do |permission_name|
  worker2.grant_permission(permission_name, shop2)
end

# Hassan (Electronics Hub) - Standard permissions
standard_permissions = basic_worker_permissions + ['create_customers', 'create_bills', 'view_reports']
standard_permissions.each do |permission_name|
  worker3.grant_permission(permission_name, shop3)
end

puts "✅ Assigned permissions to #{User.where(role: :worker).count} workers"

puts "\n🎉 Step 3 seed data created successfully!"
puts "\n📊 INVENTORY SYSTEM SUMMARY:"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "🏢 #{Business.count} Businesses with #{Shop.count} Shops"
puts "📦 #{Product.count} Products with #{ShopInventory.count} Shop Inventory Records"
puts "🔄 #{StockTransfer.count} Stock Transfers (#{StockTransfer.completed.count} completed, #{StockTransfer.pending.count} pending)"
puts "👥 #{User.count} Users (#{User.super_admin.count} super admin, #{User.business_admin.count} business admins, #{User.worker.count} workers)"
puts ""
puts "🏪 EMAAN TRADERS:"
puts "   📍 Main Warehouse: #{ShopInventory.joins(:shop).where(shops: { name: 'Main Warehouse' }).count} products"
puts "   🛒 Retail Outlet: #{ShopInventory.joins(:shop).where(shops: { name: 'Retail Outlet' }).count} products"
puts ""
puts "⚡ SHAH ELECTRONICS:"
puts "   🔌 Electronics Hub: #{ShopInventory.joins(:shop).where(shops: { name: 'Electronics Hub' }).count} products"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "\n📋 Login Credentials:"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "🔧 SYSTEM ADMINISTRATION:"
puts "   Super Admin Panel (/admin): superadmin@dukaan360.com / password123"
puts "   System Admin (Web): admin@dukaan360.com / password123"
puts ""
puts "🏢 BUSINESS 1 - EMAAN TRADERS:"
puts "   Business Admin: owner@emaantraders.com / password123"
puts "   Warehouse Worker: ali@emaantraders.com / password123 (inventory focus)"
puts "   Retail Worker: fatima@emaantraders.com / password123 (sales focus)"
puts ""
puts "🏢 BUSINESS 2 - SHAH ELECTRONICS:"
puts "   Business Admin: owner@shahelectronics.com / password123"
puts "   Shop Worker: hassan@shahelectronics.com / password123 (standard permissions)"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
food_products = [
  { name: 'Basmati Rice Premium', category: 'Grains', buying_price: 150, selling_price: 180, description: 'Premium quality basmati rice', sku: 'EM-RICE-001' },
  { name: 'Cooking Oil 1L', category: 'Oil', buying_price: 300, selling_price: 350, description: 'Pure cooking oil', sku: 'EM-OIL-001' },
  { name: 'Wheat Flour 10kg', category: 'Flour', buying_price: 800, selling_price: 950, description: 'Fine wheat flour', sku: 'EM-FLOUR-001' },
  { name: 'White Sugar 1kg', category: 'Sweeteners', buying_price: 120, selling_price: 140, description: 'Refined white sugar', sku: 'EM-SUGAR-001' },
  { name: 'Tea Bags 100pcs', category: 'Beverages', buying_price: 250, selling_price: 300, description: 'Premium tea bags', sku: 'EM-TEA-001' },
  { name: 'Red Lentils 1kg', category: 'Pulses', buying_price: 180, selling_price: 220, description: 'Cleaned red lentils', sku: 'EM-LENTIL-001' }
]

food_products.each do |product_data|
  product = Product.find_or_create_by!(name: product_data[:name], business: business1) do |p|
    p.category = product_data[:category]
    p.buying_price = product_data[:buying_price]
    p.selling_price = product_data[:selling_price]
    p.description = product_data[:description]
    p.sku = product_data[:sku]
    p.expiry_date = Date.current + rand(60..180).days
  end

  # Create shop inventories for each product
  # Main Warehouse gets more stock
  ShopInventory.find_or_create_by!(product: product, shop: shop1) do |inventory|
    min_stock = rand(20..50)
    max_stock = rand(min_stock + 50..min_stock + 200)
    reorder_point = rand(min_stock..min_stock + 20)
    
    inventory.business = business1
    inventory.quantity = rand(100..500)
    inventory.min_stock_level = min_stock
    inventory.max_stock_level = max_stock
    inventory.reorder_point = reorder_point
  end

  # Retail Outlet gets less stock
  ShopInventory.find_or_create_by!(product: product, shop: shop2) do |inventory|
    min_stock = rand(10..25)
    max_stock = rand(min_stock + 30..min_stock + 100)
    reorder_point = rand(min_stock..min_stock + 10)
    
    inventory.business = business1
    inventory.quantity = rand(30..150)
    inventory.min_stock_level = min_stock
    inventory.max_stock_level = max_stock
    inventory.reorder_point = reorder_point
  end
end

# Create Sample Products for Shah Electronics
electronics_products = [
  { name: 'LED TV 32 inch', category: 'Television', buying_price: 25000, selling_price: 30000, description: 'HD LED Television', sku: 'SE-TV-001' },
  { name: 'Mobile Phone Samsung', category: 'Mobile', buying_price: 35000, selling_price: 42000, description: 'Samsung Galaxy smartphone', sku: 'SE-MOB-001' },
  { name: 'Refrigerator 12 Cu ft', category: 'Appliances', buying_price: 45000, selling_price: 55000, description: 'Energy efficient refrigerator', sku: 'SE-REF-001' },
  { name: 'Washing Machine 7kg', category: 'Appliances', buying_price: 40000, selling_price: 48000, description: 'Automatic washing machine', sku: 'SE-WM-001' },
  { name: 'Air Conditioner 1.5 Ton', category: 'Appliances', buying_price: 55000, selling_price: 65000, description: 'Inverter AC unit', sku: 'SE-AC-001' }
]

electronics_products.each do |product_data|
  product = Product.find_or_create_by!(name: product_data[:name], business: business2) do |p|
    p.category = product_data[:category]
    p.buying_price = product_data[:buying_price]
    p.selling_price = product_data[:selling_price]
    p.description = product_data[:description]
    p.sku = product_data[:sku]
    # Electronics don't have expiry dates
  end

  # Create shop inventory for electronics hub
  ShopInventory.find_or_create_by!(product: product, shop: shop3) do |inventory|
    min_stock = rand(2..8)
    max_stock = rand(min_stock + 15..min_stock + 30)
    reorder_point = rand(min_stock..min_stock + 5)
    
    inventory.business = business2
    inventory.quantity = rand(5..25)
    inventory.min_stock_level = min_stock
    inventory.max_stock_level = max_stock
    inventory.reorder_point = reorder_point
  end
end

puts "✅ Products created: #{Product.count} products with shop inventories"

# Create some low stock scenarios for testing
# Make some items low stock in Main Warehouse
low_stock_product = business1.products.first
low_stock_inventory = low_stock_product.shop_inventories.find_by(shop: shop1)
low_stock_inventory.update!(quantity: 2, min_stock_level: 20, max_stock_level: 100, reorder_point: 25) if low_stock_inventory

# Make some items out of stock in Retail Outlet
out_of_stock_product = business1.products.second
out_of_stock_inventory = out_of_stock_product.shop_inventories.find_by(shop: shop2)
out_of_stock_inventory.update!(quantity: 0, min_stock_level: 15, max_stock_level: 80, reorder_point: 20) if out_of_stock_inventory

puts "✅ Created test scenarios: low stock and out of stock items"

# Create sample stock transfer requests
puts "\n📦 Creating sample stock transfer requests..."

if business1.products.any? && shop1.present? && shop2.present?
  # Create a pending transfer request
  transfer1 = StockTransfer.find_or_create_by!(
    product: business1.products.third,
    from_shop: shop1,
    to_shop: shop2,
    business: business1
  ) do |transfer|
    transfer.quantity = 50
    transfer.reason = 'stock_shortage'
    transfer.status = 'pending'
    transfer.initiated_by = worker2  # Retail worker requesting stock
  end

  # Create an approved transfer
  transfer2 = StockTransfer.find_or_create_by!(
    product: business1.products.fourth,
    from_shop: shop1,
    to_shop: shop2,
    business: business1
  ) do |transfer|
    transfer.quantity = 25
    transfer.reason = 'rebalancing'
    transfer.status = 'approved'
    transfer.initiated_by = worker2
    transfer.approved_by = business_admin1
    transfer.approved_at = 1.hour.ago
  end

  puts "✅ Created sample stock transfers: #{StockTransfer.count} transfers"
end

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

puts "\n🎉 Seed data created successfully!"
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
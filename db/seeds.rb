# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create Admin User for ActiveAdmin
admin_user = AdminUser.find_or_create_by!(email: 'admin@dukaan360.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
end

puts "✅ Admin User created: #{admin_user.email}"

# Create Sample Shops
shop1 = Shop.find_or_create_by!(name: 'Karachi Wholesale Store') do |shop|
  shop.address = 'Shop #123, Urdu Bazar, Karachi'
  shop.settings = {
    expiry_alert_days: 30,
    red_alert_days: 7,
    yellow_alert_days: 15
  }
end

shop2 = Shop.find_or_create_by!(name: 'Shah Alam Trading Co') do |shop|
  shop.address = 'Shop #456, Shah Alam Market, Lahore' 
  shop.settings = {
    expiry_alert_days: 45,
    red_alert_days: 10,
    yellow_alert_days: 20
  }
end

puts "✅ Shops created: #{Shop.count} shops"

# Create Sample Users for Shop 1
owner1 = User.find_or_create_by!(email: 'owner1@example.com') do |user|
  user.name = 'Ahmed Khan'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.shop = shop1
  user.role = :owner
end

worker1 = User.find_or_create_by!(email: 'worker1@example.com') do |user|
  user.name = 'Ali Hassan'
  user.password = 'password123'  
  user.password_confirmation = 'password123'
  user.shop = shop1
  user.role = :worker
end

# Create Sample Users for Shop 2
owner2 = User.find_or_create_by!(email: 'owner2@example.com') do |user|
  user.name = 'Fatima Sheikh'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.shop = shop2
  user.role = :owner
end

puts "✅ Users created: #{User.count} users"

# Create Sample Products
products_data = [
  { name: 'Basmati Rice', category: 'Grains', buying_price: 150, selling_price: 180, quantity: 100 },
  { name: 'Cooking Oil', category: 'Oil', buying_price: 300, selling_price: 350, quantity: 50 },
  { name: 'Wheat Flour', category: 'Flour', buying_price: 80, selling_price: 95, quantity: 200 },
  { name: 'Sugar', category: 'Sweeteners', buying_price: 120, selling_price: 140, quantity: 150 }
]

products_data.each do |product_data|
  [shop1, shop2].each do |shop|
    Product.find_or_create_by!(
      name: product_data[:name],
      shop: shop
    ) do |product|
      product.category = product_data[:category]
      product.buying_price = product_data[:buying_price]
      product.selling_price = product_data[:selling_price]
      product.quantity = product_data[:quantity]
      product.expiry_date = Date.current + rand(30..180).days
      product.created_by_id = shop.users.first.id
    end
  end
end

puts "✅ Products created: #{Product.count} products"

puts "\n🎉 Seed data created successfully!"
puts "\n📋 Login Credentials:"
puts "Admin Panel (/admin): admin@dukaan360.com / password123"
puts "Shop Owner 1: owner1@example.com / password123" 
puts "Shop Worker 1: worker1@example.com / password123"
puts "Shop Owner 2: owner2@example.com / password123"
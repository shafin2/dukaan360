# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create Super Admin User for ActiveAdmin
admin_user = AdminUser.find_or_create_by!(email: 'superadmin@dukaan360.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
end

puts "✅ Super Admin User created: #{admin_user.email}"
module Authorizable
  extend ActiveSupport::Concern
  
  # Simple permission check for 2-role system
  def can?(permission_name, shop = nil)
    case role
    when 'business_owner'
      # Business owners can do everything within their business
      true
    when 'shop_worker'
      # Shop workers have limited permissions
      shop_worker_permissions.include?(permission_name) && 
      (shop.nil? || shop == self.shop)
    else
      false
    end
  end
  
  # Check if user cannot perform action
  def cannot?(permission_name, shop = nil)
    !can?(permission_name, shop)
  end
  
  # Get all accessible shops for user
  def accessible_shops
    case role
    when 'business_owner'
      business&.shops || Shop.none
    when 'shop_worker'
      shop ? [shop] : []
    else
      Shop.none
    end
  end
  
  private
  
  # Define what shop workers can do
  def shop_worker_permissions
    [
      'view_products',      # Can see products in their shop
      'create_sales',       # Can make sales
      'view_sales',         # Can view sales they made
      'create_customers',   # Can create customers for credit sales
      'view_customers',     # Can view customers
      'create_bills',       # Can create bills for sales
      'view_bills'          # Can view bills they created
    ]
  end
end

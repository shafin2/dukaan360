module Authorizable
  extend ActiveSupport::Concern
  
  included do
    # Cache permissions for performance
    def cached_permissions
      @cached_permissions ||= load_user_permissions
    end
    
    # Clear cache when permissions change
    def clear_permissions_cache
      @cached_permissions = nil
    end
  end
  
  # Check if user has permission
  def can?(permission_name, shop = nil)
    return true if super_admin?
    return true if business_admin? && business_permission?(permission_name)
    
    UserPermission.has_permission?(self, permission_name, shop)
  end
  
  # Check if user cannot perform action
  def cannot?(permission_name, shop = nil)
    !can?(permission_name, shop)
  end
  
  # Grant permission to user
  def grant_permission(permission_name, shop = nil, notes = nil)
    permission = Permission.find_by(name: permission_name)
    return false unless permission
    
    user_permission = user_permissions.find_or_initialize_by(
      permission: permission,
      shop: shop
    )
    user_permission.granted = true
    user_permission.notes = notes if notes
    user_permission.save
    
    clear_permissions_cache
    user_permission
  end
  
  # Revoke permission from user
  def revoke_permission(permission_name, shop = nil, notes = nil)
    permission = Permission.find_by(name: permission_name)
    return false unless permission
    
    user_permission = user_permissions.find_by(permission: permission, shop: shop)
    if user_permission
      user_permission.update(granted: false, notes: notes)
    else
      user_permissions.create(
        permission: permission,
        shop: shop,
        granted: false,
        notes: notes
      )
    end
    
    clear_permissions_cache
  end
  
  # Get all permissions for user (grouped by category)
  def permissions_by_category(shop = nil)
    permissions = if shop
      user_permissions.joins(:permission).where(shop: [shop, nil], granted: true)
                    .includes(:permission).group_by { |up| up.permission.category }
    else
      user_permissions.joins(:permission).where(granted: true)
                    .includes(:permission).group_by { |up| up.permission.category }
    end
    
    permissions.transform_values { |user_perms| user_perms.map(&:permission) }
  end
  
  # Get all accessible shops for user
  def accessible_shops
    return Shop.all if super_admin?
    return business.shops if business_admin? && business.present?
    return [shop].compact if shop.present?
    []
  end
  
  private
  
  def business_permission?(permission_name)
    # Business admins have access to most permissions within their business
    business_admin_permissions = [
      'view_products', 'create_products', 'edit_products', 'delete_products',
      'view_customers', 'create_customers', 'edit_customers',
      'view_sales', 'create_sales', 'view_reports',
      'view_bills', 'create_bills', 'edit_bills',
      'view_payments', 'create_payments',
      'manage_inventory', 'view_buying_price',
      'manage_users', 'view_settings'
    ]
    
    business_admin_permissions.include?(permission_name)
  end
  
  def load_user_permissions
    user_permissions.joins(:permission).includes(:permission, :shop)
                  .where(granted: true).group_by(&:shop_id)
  end
end

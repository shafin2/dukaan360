module AuthorizationHelper
  # Check if current user can perform action
  def can?(permission_name, shop = nil)
    return false unless user_signed_in?
    current_user.can?(permission_name, shop)
  end
  
  # Check if current user cannot perform action  
  def cannot?(permission_name, shop = nil)
    !can?(permission_name, shop)
  end
  
  # Redirect if user lacks permission
  def authorize!(permission_name, shop = nil)
    unless can?(permission_name, shop)
      redirect_to root_path, alert: 'You do not have permission to perform this action.'
      return false
    end
    true
  end
  
  # Get permission badge color based on category
  def permission_badge_color(category)
    colors = {
      'sales' => 'bg-green-100 text-green-800',
      'inventory' => 'bg-blue-100 text-blue-800', 
      'customers' => 'bg-purple-100 text-purple-800',
      'billing' => 'bg-yellow-100 text-yellow-800',
      'reports' => 'bg-red-100 text-red-800',
      'settings' => 'bg-gray-100 text-gray-800',
      'general' => 'bg-gray-100 text-gray-800'
    }
    colors[category] || colors['general']
  end
  
  # Get role badge styling
  def role_badge_class(role)
    case role.to_s
    when 'business_owner'
      'bg-blue-100 text-blue-800 border-blue-200'
    when 'shop_worker'
      'bg-green-100 text-green-800 border-green-200'
    else
      'bg-gray-100 text-gray-800 border-gray-200'
    end
  end
  
  # Format role name for display
  def role_display_name(role)
    {
      'business_owner' => 'Business Owner',
      'shop_worker' => 'Shop Worker'
    }[role.to_s] || role.to_s.humanize
  end
  
  # Check if user has business context
  def has_business_context?
    user_signed_in? && current_user.business.present?
  end
  
  # Get current business for branding
  def current_business
    return nil unless user_signed_in?
    current_user.business
  end
  
  # Get business branding colors
  def business_primary_color
    current_business&.primary_color || '#3B82F6'
  end
  
  def business_secondary_color
    current_business&.secondary_color || '#1F2937'
  end
  
  # Check if feature should be visible based on permissions
  def feature_visible?(permission_name, shop = nil)
    return true if user_signed_in? && current_user.business_owner?
    can?(permission_name, shop)
  end
  
  # Generate permission form field name
  def permission_field_name(permission, shop = nil)
    shop_suffix = shop ? "_shop_#{shop.id}" : "_global"
    "permissions[#{permission.name}#{shop_suffix}]"
  end
  
  # Get icon for permission category
  def category_icon(category)
    icons = {
      'sales' => 'cash-register',
      'inventory' => 'boxes',
      'customers' => 'users',
      'billing' => 'file-invoice-dollar',
      'reports' => 'chart-line',
      'settings' => 'cogs',
      'general' => 'home'
    }
    icons[category] || 'circle'
  end
end

module Authenticatable
  extend ActiveSupport::Concern
  
  private
  
  # Ensure user is a business owner
  def ensure_business_owner
    unless current_user&.business_owner?
      redirect_to root_path, alert: 'Access denied. Only business owners can access this section.'
    end
  end
  
  # Ensure user belongs to a business (either owner or worker)
  def ensure_business_access
    unless current_user&.business.present?
      redirect_to root_path, alert: 'Access denied. Please contact administrator.'
    end
  end
  
  # Ensure user has access to specific shop
  def ensure_shop_access(shop)
    if current_user.business_owner?
      # Business owners can access any shop in their business
      unless shop.business == current_user.business
        redirect_to root_path, alert: 'Access denied. Shop not found in your business.'
      end
    elsif current_user.shop_worker?
      # Shop workers can only access their own shop
      unless shop == current_user.shop
        redirect_to root_path, alert: 'Access denied. You can only access your assigned shop.'
      end
    else
      redirect_to root_path, alert: 'Access denied.'
    end
  end
  
  # Get shops user can access
  def accessible_shops
    current_user&.accessible_shops || Shop.none
  end
  
  # Get businesses user can access (only for system admins via ActiveAdmin)
  def accessible_businesses
    if current_admin_user
      Business.all
    else
      Business.none
    end
  end
end

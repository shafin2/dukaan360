class PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_business_admin_or_super_admin
  before_action :set_user, only: [:show, :update]
  
  def index
    @business = current_user.business
    @users = if current_user.super_admin?
      User.includes(:business, :shop, :permissions).all
    else
      current_user.business.users.includes(:shop, :permissions)
    end
    
    @users = @users.where.not(role: :super_admin) unless current_user.super_admin?
    @permissions_by_category = Permission.user_permissions.includes(:users).group_by(&:category)
  end
  
  def show
    @permissions_by_category = Permission.user_permissions.group_by(&:category)
    @user_permissions = @user.user_permissions.includes(:permission, :shop).group_by(&:shop_id)
    @shops = @user.accessible_shops
  end
  
  def update
    success_count = 0
    error_count = 0
    
    ActiveRecord::Base.transaction do
      params[:permissions]&.each do |permission_key, value|
        permission_name, shop_id = parse_permission_key(permission_key)
        shop = shop_id ? Shop.find(shop_id) : nil
        
        # Validate user can manage this shop
        unless can_manage_shop?(shop)
          error_count += 1
          next
        end
        
        if value == '1' || value == 'true'
          @user.grant_permission(permission_name, shop)
          success_count += 1
        else
          @user.revoke_permission(permission_name, shop)
        end
      end
    end
    
    if error_count == 0
      redirect_to permissions_path, notice: "Successfully updated #{success_count} permissions for #{@user.name}"
    else
      redirect_to permissions_path, alert: "Updated #{success_count} permissions, but #{error_count} failed due to access restrictions"
    end
  rescue => e
    redirect_to permissions_path, alert: "Error updating permissions: #{e.message}"
  end
  
  private
  
  def set_user
    @user = if current_user.super_admin?
      User.find(params[:id])
    else
      current_user.business.users.find(params[:id])
    end
  end
  
  def ensure_business_admin_or_super_admin
    unless current_user.super_admin? || current_user.business_admin?
      redirect_to root_path, alert: 'Access denied. Only business administrators can manage permissions.'
    end
  end
  
  def parse_permission_key(key)
    # Format: "permission_name_shop_123" or "permission_name_global"
    if key.end_with?('_global')
      [key.gsub('_global', ''), nil]
    elsif key.match(/_shop_(\d+)$/)
      permission_name = key.gsub(/_shop_\d+$/, '')
      shop_id = key.match(/_shop_(\d+)$/)[1].to_i
      [permission_name, shop_id]
    else
      [key, nil]
    end
  end
  
  def can_manage_shop?(shop)
    return true if current_user.super_admin?
    return true if shop.nil? # Global permissions
    return true if current_user.business_admin? && shop.business == current_user.business
    false
  end
end

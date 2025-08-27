class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_shop_access
  layout 'dashboard'
  
  def index
    @shop = current_user.shop
    @total_products = @shop.products.count
    @low_stock_items = @shop.products.where('quantity <= ?', 5).count  # For wholesale: 5 packs is low
    @today_sales = @shop.sales.where(created_at: Date.current.all_day).sum(:total_amount)
    @recent_sales = @shop.sales.includes(:user, :product).order(created_at: :desc).limit(5)
    
    # Expiry alerts for wholesale business
    @expiring_critical = @shop.products.expiring_critical.count  # 15 days or less
    @expiring_warning = @shop.products.expiring_soon.count      # 30 days or less
    @expired_products = @shop.products.expired.count
    
    # Calculate total revenue (you might want to add date filtering later)
    @total_revenue = @shop.sales.sum(:total_amount)
    
    # Total inventory value
    @inventory_value = @shop.products.sum('quantity * buying_price')
  end
  
  private
  
  def ensure_shop_access
    unless current_user.shop.present?
      redirect_to root_path, alert: 'Access denied. Please contact administrator.'
    end
  end
end

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_business_access
  layout 'dashboard'
  
  def index
    if current_user.business_admin?
      # Business admin dashboard - overview of all shops
      business_admin_dashboard
    else
      # Shop worker dashboard - specific shop view
      shop_worker_dashboard
    end
  end
  
  private
  
  def business_admin_dashboard
    @business = current_user.business
    @shops = @business.shops.includes(:users, :shop_inventories)
    
    # Business-wide metrics
    @total_shops = @shops.count
    @total_products = @business.products.count
    @total_inventory_items = @business.shop_inventories.sum(:quantity)
    @total_inventory_value = @business.shop_inventories
                                    .joins(:product)
                                    .sum('quantity * products.selling_price')
    
    # Today's sales across all shops
    @today_sales = Sale.joins(user: :shop)
                      .where(shops: { business: @business })
                      .where(created_at: Date.current.all_day)
                      .sum(:total_amount)
    
    # Low stock alerts across all shops
    @low_stock_items = @business.shop_inventories
                              .joins(:product)
                              .where('shop_inventories.quantity <= shop_inventories.min_stock_level')
                              .count
    @critical_stock_items = @business.shop_inventories
                                   .where('quantity = 0')
                                   .count
    
    # Pending stock transfer approvals
    @pending_transfers = @business.stock_transfers.pending.count
    
    # Recent transfers requiring attention
    @recent_transfers = @business.stock_transfers
                               .pending
                               .includes(:product, :from_shop, :to_shop, :initiated_by)
                               .order(created_at: :desc)
                               .limit(5)
    
    # Shop performance summary
    @shop_metrics = @shops.map do |shop|
      {
        shop: shop,
        inventory_count: shop.shop_inventories.sum(:quantity),
        inventory_value: shop.shop_inventories.joins(:product)
                            .sum('quantity * products.selling_price'),
        today_sales: shop.users.joins(:sales)
                         .where(sales: { created_at: Date.current.all_day })
                         .sum('sales.total_amount'),
        low_stock_count: shop.shop_inventories
                            .where('shop_inventories.quantity <= shop_inventories.min_stock_level')
                            .count,
        active_users: shop.users.count
      }
    end
    
    # Recent activity across all shops
    @recent_sales = Sale.joins(user: :shop)
                       .where(shops: { business: @business })
                       .includes(:user, :product, user: :shop)
                       .order(created_at: :desc)
                       .limit(10)
  end
  
  def shop_worker_dashboard
    @shop = current_user.shop
    @business = current_user.business
    
    # Shop-specific metrics
    @total_products = @shop.shop_inventories.count
    @total_inventory_items = @shop.shop_inventories.sum(:quantity)
    @inventory_value = @shop.shop_inventories
                           .joins(:product)
                           .sum('quantity * products.selling_price')
    
    # Today's sales for this shop
    @today_sales = @shop.users.joins(:sales)
                       .where(sales: { created_at: Date.current.all_day })
                       .sum('sales.total_amount')
    
    # Low stock alerts for this shop
        @low_stock_items = current_user.shop.shop_inventories
                            .joins(:product)
                            .where('shop_inventories.quantity <= shop_inventories.min_stock_level')
                            .count
    @critical_stock_items = @shop.shop_inventories
                               .where('quantity = 0')
                               .count
    
    # Recent sales for this shop
    @recent_sales = Sale.joins(:user)
                       .where(users: { shop: @shop })
                       .includes(:user, :product)
                       .order(created_at: :desc)
                       .limit(5)
    
    # Stock transfers involving this shop
    @pending_transfers_out = StockTransfer.where(from_shop: @shop, status: 'pending').count
    @recent_transfers = StockTransfer.where(
      "(from_shop_id = ? OR to_shop_id = ?) AND business_id = ?", 
      @shop.id, @shop.id, @business.id
    ).includes(:product, :from_shop, :to_shop)
     .order(created_at: :desc)
     .limit(5)
    
    # Revenue calculation for this shop
    @total_revenue = Sale.joins(:user)
                        .where(users: { shop: @shop })
                        .sum(:total_amount)
    
    # Top selling products in this shop
    @top_products = @shop.shop_inventories
                        .joins(:product, product: :sales)
                        .where(sales: { user: @shop.users })
                        .group('products.name')
                        .order('SUM(sales.quantity) DESC')
                        .limit(5)
                        .pluck('products.name', 'SUM(sales.quantity)')
  end
  
  private
  
  def ensure_business_access
    unless current_user.business.present?
      redirect_to root_path, alert: 'Access denied. Please contact administrator.'
    end
  end
end

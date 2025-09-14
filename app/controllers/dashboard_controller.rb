class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_business_access
  layout 'dashboard'
  
  def index
    if current_user.business_owner?
      business_owner_dashboard
    elsif current_user.shop_worker?
      shop_worker_dashboard
    else
      redirect_to root_path, alert: 'Access denied.'
    end
  end
  
  private
  
  def business_owner_dashboard
    # Business-wide metrics
    @total_sales = business_sales.sum(:total_amount)
    @total_bills = business_bills.count
    @total_customers = business_customers.count
    @total_receivables = business_bills.where(status: ['pending', 'partial']).sum { |bill| bill.outstanding_amount }
    
    # Time-based metrics
    @today_sales = business_sales.where(created_at: Date.current.all_day).sum(:total_amount)
    @this_month_sales = business_sales.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).sum(:total_amount)
    @last_month_sales = business_sales.where(created_at: Date.current.last_month.beginning_of_month..Date.current.last_month.end_of_month).sum(:total_amount)
    
    # Growth calculation
    @monthly_growth = @last_month_sales > 0 ? ((@this_month_sales - @last_month_sales) / @last_month_sales * 100).round(1) : 0
    
    # Shop performance overview
    @shop_performance = current_user.business.shops.includes(:users, :bills, :shop_inventories).limit(6).map do |shop|
      shop_sales = shop.users.joins(:sales).where(sales: { created_at: 1.month.ago..Time.current }).sum('sales.total_amount')
      shop_bills = shop.bills.where(created_at: 1.month.ago..Time.current).count
      
      {
        shop: shop,
        sales_amount: shop_sales,
        bills_count: shop_bills,
        workers_count: shop.users.count,
        products_count: shop.shop_inventories.count
      }
    end
    
    # Recent activities across all shops
    @recent_sales = business_sales.includes(:product, :user).order(created_at: :desc).limit(10)
    @recent_bills = business_bills.includes(:customer, :user, :shop).order(created_at: :desc).limit(5)
    
    # Top products across all shops
    @top_products = business_sales.joins(:product)
                                  .where(created_at: 1.month.ago..Time.current)
                                  .group('products.name')
                                  .sum(:total_amount)
                                  .sort_by { |_, amount| -amount }
                                  .first(5)
    
    # Inventory alerts
    @low_stock_count = current_user.business.shop_inventories.where('quantity <= min_stock_level').count
    @out_of_stock_count = current_user.business.shop_inventories.where(quantity: 0).count
    @unassigned_products_count = current_user.business.products.where('business_inventory_quantity > 0').count
  end
  
  def shop_worker_dashboard
    # Shop-specific metrics for worker
    @shop = current_user.shop
    @today_sales = current_user.sales.where(created_at: Date.current.all_day).sum(:total_amount)
    @this_month_sales = current_user.sales.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).sum(:total_amount)
    @total_sales = current_user.sales.sum(:total_amount)
    
    # Worker's performance
    @sales_count = current_user.sales.count
    @customers_count = current_user.customers.count
    @pending_bills_count = current_user.bills.where(status: ['pending', 'partial']).count
    
    # Shop inventory for worker
    @shop_products_count = @shop.shop_inventories.count
    @low_stock_products = @shop.shop_inventories.where('quantity <= min_stock_level').includes(:product).limit(5)
    @out_of_stock_count = @shop.shop_inventories.where(quantity: 0).count
    
    # Recent activities
    @recent_sales = current_user.sales.includes(:product).order(created_at: :desc).limit(5)
    @recent_bills = current_user.bills.includes(:customer).order(created_at: :desc).limit(3)
    
    # Top selling products for this worker
    @top_products = current_user.sales.joins(:product)
                                     .where(created_at: 1.month.ago..Time.current)
                                     .group('products.name')
                                     .sum(:total_amount)
                                     .sort_by { |_, amount| -amount }
                                     .first(5)
  end
  
  def business_sales
    @business_sales ||= Sale.joins(:user).where(users: { business: current_user.business })
  end
  
  def business_bills
    @business_bills ||= Bill.joins(:user).where(users: { business: current_user.business })
  end
  
  def business_customers
    @business_customers ||= Customer.joins(:user).where(users: { business: current_user.business })
  end
  
  def ensure_business_access
    unless current_user.business.present?
      redirect_to root_path, alert: 'Access denied. Please contact administrator.'
    end
  end
end

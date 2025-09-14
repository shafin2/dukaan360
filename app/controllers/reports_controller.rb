class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_business_owner
  layout 'dashboard'
  
  def index
    @date_range = get_date_range
    
    # Overall business metrics
    @total_sales = business_sales.sum(:total_amount)
    @total_bills = business_bills.count
    @total_customers = business_customers.count
    @total_receivables = business_bills.where(status: ['pending', 'partial']).sum { |bill| bill.outstanding_amount }
    
    # Time-based metrics
    @today_sales = business_sales.where(created_at: Date.current.all_day).sum(:total_amount)
    @this_month_sales = business_sales.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).sum(:total_amount)
    @last_month_sales = business_sales.where(created_at: Date.current.last_month.beginning_of_month..Date.current.last_month.end_of_month).sum(:total_amount)
    
    # Shop-wise performance
    @shop_performance = current_user.business.shops.includes(:users, :bills, :shop_inventories).map do |shop|
      shop_sales = shop.users.joins(:sales).where(sales: { created_at: @date_range }).sum('sales.total_amount')
      shop_bills = shop.bills.where(created_at: @date_range).count
      shop_customers = shop.customers.count
      
      {
        shop: shop,
        sales_amount: shop_sales,
        bills_count: shop_bills,
        customers_count: shop_customers,
        workers_count: shop.users.count,
        products_count: shop.shop_inventories.count
      }
    end
    
    # Top products across all shops
    @top_products = business_sales.joins(:product)
                                  .where(created_at: @date_range)
                                  .group('products.name')
                                  .sum(:total_amount)
                                  .sort_by { |_, amount| -amount }
                                  .first(10)
    
    # Recent sales across all shops
    @recent_sales = business_sales.includes(:product, :user)
                                  .order(created_at: :desc)
                                  .limit(20)
    
    # Monthly trend data for charts (simplified without groupdate gem)
    @monthly_sales = business_sales.where('sales.created_at >= ?', 12.months.ago)
                                   .group("DATE_TRUNC('month', sales.created_at)")
                                   .sum(:total_amount)
  end
  
  def sales_by_shop
    @shop = current_user.business.shops.find(params[:shop_id]) if params[:shop_id].present?
    @date_range = get_date_range
    
    if @shop
      @sales = @shop.users.joins(:sales)
                         .where(sales: { created_at: @date_range })
                         .includes(sales: [:product])
                         .map(&:sales).flatten
                         .sort_by(&:created_at).reverse
                         .paginate(page: params[:page], per_page: 50)
      
      @shop_total = @sales.sum(&:total_amount)
    else
      @sales = business_sales.where(created_at: @date_range)
                            .includes(:product, :user)
                            .order(created_at: :desc)
                            .paginate(page: params[:page], per_page: 50)
      @shop_total = @sales.sum(&:total_amount)
    end
    
    @shops = current_user.business.shops
  end
  
  def receivables
    @bills = business_bills.where(status: ['pending', 'partial'])
                          .includes(:customer, :user, :shop, :payments)
                          .order(:bill_date)
                          .paginate(page: params[:page], per_page: 20)
    
    @total_receivables = @bills.sum { |bill| bill.outstanding_amount }
    @overdue_bills = @bills.select { |bill| bill.bill_date < 30.days.ago }
    @overdue_amount = @overdue_bills.sum { |bill| bill.outstanding_amount }
  end
  
  def inventory_report
    @products = current_user.business.products
                           .includes(:shop_inventories => :shop)
                           .order(:name)
                           .paginate(page: params[:page], per_page: 50)
    
    @total_business_inventory = current_user.business.products.sum(:business_inventory_quantity)
    @total_shop_inventory = current_user.business.shop_inventories.sum(:quantity)
    @low_stock_products = current_user.business.shop_inventories
                                     .where('quantity <= min_stock_level')
                                     .includes(:product, :shop)
    
    @inventory_value = current_user.business.shop_inventories
                                  .joins(:product)
                                  .sum('quantity * products.selling_price')
  end
  
  private
  
  def ensure_business_owner
    unless current_user.business_owner?
      redirect_to dashboard_index_path, alert: 'Access denied. Reports are only available to business owners.'
    end
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
  
  def get_date_range
    case params[:period]
    when 'today'
      Date.current.all_day
    when 'week'
      1.week.ago..Time.current
    when 'month'
      1.month.ago..Time.current
    when 'quarter'
      3.months.ago..Time.current
    when 'year'
      1.year.ago..Time.current
    when 'custom'
      if params[:start_date].present? && params[:end_date].present?
        Date.parse(params[:start_date])..Date.parse(params[:end_date])
      else
        1.month.ago..Time.current
      end
    else
      1.month.ago..Time.current
    end
  end
end
